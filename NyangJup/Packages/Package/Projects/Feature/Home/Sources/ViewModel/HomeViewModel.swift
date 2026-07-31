//
//  HomeViewModel.swift
//  NJPackage
//
//  Created by 정지훈 on 7/1/26.
//

import Foundation

import DomainCatsInterface
import DomainProfileInterface
import FeatureCommonInterface
import FeatureHomeInterface

@MainActor
@Observable
public final class HomeViewModel: NZViewModel {

    public struct State {
        // keychain
        let uuidString: String = UUID().uuidString
        var cats: [Cat] = []
        var individualCode: String = ""
        var isMakeCatPresented: Bool = false
        var selectedCatId: String?
        var deletedCatIds: Set<String> = []
        var updatedCatsById: [String: Cat] = [:]

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
            case makeCatSubmitted(name: String, appearanceKey: String)
            case catTapped(id: String)
            case selectionCleared
            case speechBubbleTapped
        }

        public enum Network {

        }

        public enum Internal {
            case catDeleted(id: String)
            case catUpdated(Cat)
        }
    }

    public var state: State = State()
    weak var coordinator: (any Coordinator<HomeRoute>)?

    let catsClient: CatsClient
    let profileClient: ProfileClient

    public init(
        catsClient: CatsClient,
        profileClient: ProfileClient,
        coordinator: any Coordinator<HomeRoute>
    ) {
        self.catsClient = catsClient
        self.profileClient = profileClient
        self.coordinator = coordinator
    }

    public func send(_ action: Action) {
        switch action {
        case let .view(viewAction):
            handleViewAction(viewAction)

        case let .internal(internalAction):
            handleInternalAction(internalAction)

        case .network:
            break
        }
    }

    private func handleViewAction(_ action: Action.View) {
        switch action {
        case .onAppear:
            Task {
                do {
                    let cats = try await catsClient.fetchCats(state.individualCode)
                    let visibleCats = cats
                        .filter {
                            !state.deletedCatIds.contains($0.id)
                        }
                        .map {
                            state.updatedCatsById[$0.id] ?? $0
                        }
                    let fetchedCatIDs = Set(visibleCats.map(\.id))
                    let locallyAddedCats = state.cats.filter {
                        !fetchedCatIDs.contains($0.id)
                            && !state.deletedCatIds.contains($0.id)
                    }
                    state.cats = visibleCats + locallyAddedCats
                } catch {

                }
            }
        case .plusButtonTapped:
            state.selectedCatId = nil
            state.isMakeCatPresented = true

        case let .makeCatSubmitted(name, appearanceKey):
            Task {
                do {
                    let cat = try await catsClient.createCat(
                        CreateCatRequestDTO(
                            name: name,
                            appearanceKey: appearanceKey
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
        case let .catDeleted(id):
            state.deletedCatIds.insert(id)
            state.updatedCatsById[id] = nil
            state.cats.removeAll { $0.id == id }
            if state.selectedCatId == id {
                state.selectedCatId = nil
            }

        case let .catUpdated(cat):
            guard let index = state.cats.firstIndex(where: { $0.id == cat.id }) else {
                return
            }
            state.updatedCatsById[cat.id] = cat
            state.cats[index] = cat
        }
    }
}
