//
//  HomeViewModel.swift
//  NJPackage
//
//  Created by 정지훈 on 7/1/26.
//

import Foundation

import CoreAdsInterface
import DomainCatsInterface
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

    public init(
        catsClient: CatsClient,
        profileClient: ProfileClient,
        adsClient: AdsClient,
        coordinator: any Coordinator<HomeRoute>
    ) {
        self.catsClient = catsClient
        self.profileClient = profileClient
        self.coordinator = coordinator
        self.adsClient = adsClient
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
        case .plusButtonTapped:
            if state.cats.count == 0 {
                state.selectedCatId = nil
                state.isMakeCatPresented = true
            } else {
                guard state.cats.count < Self.maximumCatCount else {
                    state.showsCatLimitAlert = true
                    return
                }

                Task {
                    do {
                        let didWatcedReward = try await adsClient.showRewardAds()
                        guard didWatcedReward else { return }

                        state.selectedCatId = nil
                        state.isMakeCatPresented = true

                    } catch {

                    }
                }
            }

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

        case .catRegistrationClosed:
            state.isMakeCatPresented = false

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
        }
    }
}
