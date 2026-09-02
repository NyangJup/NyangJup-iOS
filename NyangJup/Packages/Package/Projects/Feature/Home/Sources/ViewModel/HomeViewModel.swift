//
//  HomeViewModel.swift
//  NJPackage
//
//  Created by 정지훈 on 7/1/26.
//

import Foundation

import CoreAdsInterface
import DomainCatsInterface
import DomainPixelRewardInterface
import DomainProfileInterface
import FeatureCommonInterface
import FeatureHomeInterface

@MainActor
@Observable
public final class HomeViewModel: NZViewModel {

    nonisolated static let maximumCatCount = 5

    public struct State {
        // keychain
        let uuidString: String = UUID().uuidString
        var cats: [Cat] = []
        var individualCode: String = ""
        var isMakeCatPresented: Bool = false
        var showsCatLimitAlert: Bool = false
        var selectedCatId: String?
        var isFetching: Bool = false
        var pixelRewardBalance: Int64?
        var pendingAdSession: PixelRewardAdSession?
        var hasEarnedPendingAdReward = false
        var isRewardFlowInProgress = false

        var selectedCat: Cat? {
            guard let selectedCatId else { return nil }

            return cats.first { $0.id == selectedCatId }
        }
    }

    public enum Action {
        case view(View)
        case network(Network)
        case `internal`(Internal)

        public enum View {
            case onAppear
            case plusButtonTapped
            case makeCatSubmitted(name: String, imageURL: String)
            case catTapped(id: String)
            case selectionCleared
            case speechBubbleTapped
        }

        public enum Network {
            case fetchCats
            case fetchPixelRewardBalance
        }

        public enum Internal {
            case catRegistered(Cat)
            case catRegistrationClosed
            case catDeleted(id: String)
            case catUpdated(Cat)
        }
    }

    public var state: State = State()
    weak var coordinator: (any Coordinator<HomeRoute>)?

    let catsClient: CatsClient
    let profileClient: ProfileClient
    let adsClient: AdsClient
    let pixelRewardClient: PixelRewardClient

    public init(
        catsClient: CatsClient,
        profileClient: ProfileClient,
        adsClient: AdsClient,
        pixelRewardClient: PixelRewardClient,
        coordinator: any Coordinator<HomeRoute>
    ) {
        self.catsClient = catsClient
        self.profileClient = profileClient
        self.coordinator = coordinator
        self.adsClient = adsClient
        self.pixelRewardClient = pixelRewardClient
    }

    public func send(_ action: Action) {
        switch action {
        case let .view(viewAction):
            handleViewAction(viewAction)

        case let .internal(internalAction):
            handleInternalAction(internalAction)

        case let .network(networkAction):
            handleNetworkAction(networkAction)
        }
    }

    private func handleViewAction(_ action: Action.View) {
        switch action {
        case .onAppear:
            send(.network(.fetchCats))
            send(.network(.fetchPixelRewardBalance))
        case .plusButtonTapped:
            guard state.cats.count < Self.maximumCatCount else {
                state.showsCatLimitAlert = true
                return
            }
            startPixelRewardFlow()

        case let .makeCatSubmitted(name, imageURL):
            guard state.cats.count < Self.maximumCatCount else {
                state.isMakeCatPresented = false
                state.showsCatLimitAlert = true
                return
            }
            Task {
                do {
                    let cat = try await catsClient.createCat(
                        CreateCatRequestDTO(
                            name: name,
                            fileName: imageURL
                        )
                    )
                    state.cats.append(cat)
                    state.isMakeCatPresented = false
                    send(.network(.fetchPixelRewardBalance))
                } catch {

                }
            }
        case let .catTapped(id):
            state.selectedCatId = id

        case .selectionCleared:
            state.selectedCatId = nil

        case .speechBubbleTapped:
            guard let selectedCatId = state.selectedCatId else { return }
            coordinator?.push(to: .feed(catId: selectedCatId))
        }

    }

    private func handleInternalAction(_ action: Action.Internal) {
        switch action {
        case let .catRegistered(cat):
            state.cats.append(cat)
            state.isMakeCatPresented = false
            send(.network(.fetchPixelRewardBalance))

        case .catRegistrationClosed:
            state.isMakeCatPresented = false
            send(.network(.fetchPixelRewardBalance))

        case let .catDeleted(id):
            state.cats.removeAll { $0.id == id }
            if state.selectedCatId == id {
                state.selectedCatId = nil
            }

        case let .catUpdated(cat):
            guard let index = state.cats.firstIndex(where: { $0.id == cat.id }) else {
                return
            }
            state.cats[index] = cat
        }
    }

    private func handleNetworkAction(_ action: Action.Network) {
        switch action {
        case .fetchCats:
            state.isFetching = true

            Task {
                defer { state.isFetching = false }
                do {
                    let cats = try await catsClient.fetchCats(state.individualCode)
                    let fetchedCatIDs = Set(cats.map(\.id))
                    let locallyAddedCats = state.cats.filter {
                        !fetchedCatIDs.contains($0.id)
                    }
                    state.cats = cats + locallyAddedCats

                    try await adsClient.loadRewardAds()
                } catch {

                }
            }

        case .fetchPixelRewardBalance:
            Task {
                do {
                    let balance = try await pixelRewardClient.fetchBalance()
                    state.pixelRewardBalance = balance.balance
                    if balance.balance > 0 {
                        clearPendingAdSession()
                    }
                } catch {

                }
            }
        }
    }

    private func startPixelRewardFlow() {
        guard !state.isRewardFlowInProgress else { return }
        state.isRewardFlowInProgress = true

        Task {
            defer { state.isRewardFlowInProgress = false }

            do {
                let currentBalance = try await pixelRewardClient.fetchBalance()
                state.pixelRewardBalance = currentBalance.balance

                if currentBalance.balance > 0 {
                    clearPendingAdSession()
                    presentCatRegistration()
                    return
                }

                let session = try await reusableAdSession()
                if !state.hasEarnedPendingAdReward {
                    let earnedReward = try await adsClient.showRewardAds()
                    guard earnedReward else { return }
                    state.hasEarnedPendingAdReward = true
                }

                let claimedBalance = try await pixelRewardClient.claimAdReward(session.sessionId)
                state.pixelRewardBalance = claimedBalance.balance
                clearPendingAdSession()

                guard claimedBalance.balance > 0 else { return }
                presentCatRegistration()
            } catch PixelRewardError.sessionNotFound {
                clearPendingAdSession()
            } catch {

            }
        }
    }

    private func reusableAdSession() async throws -> PixelRewardAdSession {
        if let session = state.pendingAdSession,
           session.expiresAt > Date.now {
            return session
        }

        clearPendingAdSession()
        let session = try await pixelRewardClient.createAdSession()
        state.pendingAdSession = session
        return session
    }

    private func clearPendingAdSession() {
        state.pendingAdSession = nil
        state.hasEarnedPendingAdReward = false
    }

    private func presentCatRegistration() {
        state.selectedCatId = nil
        state.isMakeCatPresented = true
    }
}
