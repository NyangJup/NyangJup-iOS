//
//  FeedViewModel.swift
//  NJPackage
//
//  Created by 정지훈 on 7/16/26.
//

import Foundation

import DomainMediaInterface
import DomainCatsInterface
import FeatureCommonInterface
import FeatureHomeInterface

@MainActor
@Observable
public final class FeedViewModel: NZViewModel {

    nonisolated static let nameMaxLength = 5
    nonisolated static let placeMaxLength = 20

    public struct State {
        var cat: Cat
        var items: [Media] = []
        var nextCursor: String?
        var isLoading: Bool = false
        var isCameraPresented: Bool = false
        var showsEditAlert: Bool = false
        var showsDeleteAlert: Bool = false
        var editName: String = ""
        var editPlace: String = ""

        var canUpdateProfile: Bool {
            !editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !editPlace.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && editName.count <= FeedViewModel.nameMaxLength
                && editPlace.count <= FeedViewModel.placeMaxLength
        }

        public init(
            cat: Cat
        ) {
            self.cat = cat
        }
    }

    public enum Action {
        case view(View)
        case network(Network)
        case `internal`(Internal)

        public enum View {
            case onAppear
            case loadNextPage
            case feedContentTapped(Media)
            case plusButtonTapped
            case cameraCompleted(Media)
            case cameraDismissed
            case editButtonTapped
            case updateProfileAlertTapped
            case deleteButtonTapped
            case deleteAlertTapped
        }

        public enum Network {
            case fetchFeed(cursor: String?)
        }

        public enum Internal {

        }
    }

    public var state: State
    weak var coordinator: (any Coordinator<HomeRoute>)?
    let catsClient: CatsClient
    let mediaClient: MediaClient
    private let onCatDeleted: @MainActor @Sendable (String) -> Void
    private let onCatUpdated: @MainActor @Sendable (Cat) -> Void

    public init(
        cat: Cat,
        catsClient: CatsClient,
        mediaClient: MediaClient,
        onCatDeleted: @escaping @MainActor @Sendable (String) -> Void,
        onCatUpdated: @escaping @MainActor @Sendable (Cat) -> Void,
        coordinator: (any Coordinator<HomeRoute>)? = nil
    ) {
        self.state = State(cat: cat)
        self.catsClient = catsClient
        self.mediaClient = mediaClient
        self.onCatDeleted = onCatDeleted
        self.onCatUpdated = onCatUpdated
        self.coordinator = coordinator
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
            guard state.items.isEmpty else { return }
            send(.network(.fetchFeed(cursor: nil)))

        case .loadNextPage:
            guard let nextCursor = state.nextCursor else { return }
            send(.network(.fetchFeed(cursor: nextCursor)))

        case let .feedContentTapped(media):
            coordinator?.push(to: .relayCat(
                RelayCat(
                    mediaId: media.id,
                    catId: media.catId,
                    userId: media.userId,
                    comment: media.comment,
                    thumbnailURL: media.thumbnailURL,
                    name: state.cat.name,
                    catImageURL: state.cat.imageURL,
                    mediaType: media.mediaType,
                    mediaURL: media.mediaURL,
                    isLiked: false
                )
            ))
            
        case .plusButtonTapped:
            state.isCameraPresented = true

        case let .cameraCompleted(media):
            state.isCameraPresented = false
            state.items.insert(media, at: 0)

        case .cameraDismissed:
            state.isCameraPresented = false

        case .editButtonTapped:
            state.editName = state.cat.name
            state.editPlace = state.cat.place ?? ""
            state.showsEditAlert = true

        case .updateProfileAlertTapped:
            let name = state.editName.trimmingCharacters(in: .whitespacesAndNewlines)
            let place = state.editPlace.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty,
                  !place.isEmpty,
                  name.count <= Self.nameMaxLength,
                  place.count <= Self.placeMaxLength else {
                return
            }

            Task {
                do {
                    let updatedCat = try await catsClient.updateCatProfile(
                        state.cat.id,
                        UpdateCatProfileRequestDTO(
                            name: name,
                            place: place
                        )
                    )
                    state.cat = updatedCat
                    onCatUpdated(updatedCat)
                } catch {

                }
            }

        case .deleteButtonTapped:
            state.showsDeleteAlert = true

        case .deleteAlertTapped:
            Task {
                do {
                    let catId = state.cat.id
                    try await catsClient.deleteCat(catId)
                    onCatDeleted(catId)
                    coordinator?.pop()
                } catch {

                }
            }
        }
    }

    private func handleInternalAction(_ action: Action.Internal) {
        switch action {

        }
    }

    private func handleNetworkAction(_ action: Action.Network) {
        switch action {
        case let .fetchFeed(cursor):
            guard !state.isLoading else { return }
            state.isLoading = true

            Task {
                defer { state.isLoading = false }

                do {
                    let page = try await mediaClient.fetchFeeds(
                        state.cat.id,
                        cursor
                    )

                    if cursor == nil {
                        state.items = page.items
                    } else {
                        state.items.append(contentsOf: page.items)
                    }
                    state.nextCursor = page.nextCursor
                } catch {

                }
            }
        }
    }

}
