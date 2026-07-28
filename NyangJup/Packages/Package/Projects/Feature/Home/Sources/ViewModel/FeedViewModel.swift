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

    public struct State {
        var cat: Cat
        var items: [Media] = []
        var nextCursor: String?
        var isLoading: Bool = false
        var isCameraPresented: Bool = false

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
        }

        public enum Network {
            case fetchFeed(cursor: String?)
        }

        public enum Internal {

        }
    }

    public var state: State
    weak var coordinator: (any Coordinator<HomeRoute>)?
    let mediaClient: MediaClient

    public init(
        cat: Cat,
        mediaClient: MediaClient,
        coordinator: (any Coordinator<HomeRoute>)? = nil
    ) {
        self.state = State(cat: cat)
        self.mediaClient = mediaClient
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
