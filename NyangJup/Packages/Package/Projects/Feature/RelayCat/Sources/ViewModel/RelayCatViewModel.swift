//
//  RelayCatViewModel.swift
//  NJPackage
//
//  Created by 정지훈 on 7/22/26.
//

import Foundation

import CoreImageLoaderInterface
import DomainMediaInterface
import FeatureCommonInterface
import FeatureRelayCatInterface

@MainActor
@Observable
final class RelayCatViewModel: NZViewModel {
    struct State {
        let anchorId: String
        let catId: String
        var items: [RelayCat]
        var currentItemId: String?
        var previousCursor: String?
        var nextCursor: String?
        var isLoading = false
        var isLoadingPrevious = false
        var isLoadingNext = false
        
        var imageId: String = ""
        var imageSize: CGSize = .zero
        var scale: CGFloat = .zero

        init(configuration: RelayCatConfiguration) {
            self.anchorId = configuration.relayCat.id
            self.catId = configuration.catId
            self.items = [configuration.relayCat]
            self.currentItemId = configuration.relayCat.id
        }
    }

    enum Action {
        case view(View)
        case network(Network)

        enum View {
            case onAppear(CGFloat)
            case itemAppeared(id: String, size: CGSize)
        }
        
        enum Network {  
            case fetchRelayCats
            case fetchPreviousRelayCats
            case fetchNextRelayCats
            case updateIsLiked(id: String, isLiked: Bool)
        }
    }

    var state: State
    private let mediaClient: MediaClient
    private let imageLoaderClient: ImageLoaderClient
    private var imagePreloadTask: Task<Void, Never>?

    init(
        configuration: RelayCatConfiguration,
        mediaClient: MediaClient,
        imageLoaderClient: ImageLoaderClient
    ) {
        self.state = State(configuration: configuration)
        self.mediaClient = mediaClient
        self.imageLoaderClient = imageLoaderClient
    }

    func send(_ action: Action) {
        switch action {
        case let .view(action):
            handleViewAction(action)
            
        case let .network(action):
            handleNetworkAction(action)
        }
    }
    
    func handleViewAction(_ action: Action.View) {
        switch action {
        case let .onAppear(scale):
            state.scale = scale
            send(.network(.fetchRelayCats))

        case let .itemAppeared(id, size):
            state.imageId = id
            state.imageSize = size
            preloadAdjacentImages()

            if id == state.items.first?.id {
                send(.network(.fetchPreviousRelayCats))
            }

            if id == state.items.last?.id {
                send(.network(.fetchNextRelayCats))
            }

        }
    }
    
    func handleNetworkAction(_ action: Action.Network) {
        switch action {
        case .fetchRelayCats:
            fetchInitialRelayCats()

        case .fetchPreviousRelayCats:
            fetchPreviousRelayCats()

        case .fetchNextRelayCats:
            fetchNextRelayCats()

        case let .updateIsLiked(id, isLiked):
            updateIsLiked(id: id, isLiked: isLiked)
        }
    }

    private func fetchInitialRelayCats() {
        guard !state.isLoading else { return }
        state.isLoading = true

        Task {
            defer { state.isLoading = false }

            let dto = FetchRelayCatsRequestDTO(
                anchorId: state.anchorId,
                catId: state.catId,
                beforeCount: 5,
                afterCount: 5
            )

            do {
                let response = try await mediaClient.fetchRelayCats(dto)
                guard !response.items.isEmpty else { return }

                state.items = response.items
                state.previousCursor = response.previousCursor
                state.nextCursor = response.nextCursor

                if response.items.indices.contains(response.anchorIndex) {
                    state.currentItemId = response.items[response.anchorIndex].id
                }

                preloadAdjacentImages()
            } catch {

            }
        }
    }

    private func fetchPreviousRelayCats() {
        guard
            state.previousCursor != nil,
            !state.isLoadingPrevious,
            let anchorId = state.items.first?.id
        else { return }

        state.isLoadingPrevious = true

        Task {
            defer { state.isLoadingPrevious = false }

            let dto = FetchRelayCatsRequestDTO(
                anchorId: anchorId,
                catId: state.catId,
                beforeCount: 5,
                afterCount: 0
            )

            do {
                let response = try await mediaClient.fetchRelayCats(dto)
                let existingIds = Set(state.items.map(\.id))
                let previousItems = response.items.filter {
                    !existingIds.contains($0.id)
                }

                state.items.insert(contentsOf: previousItems, at: 0)
                state.previousCursor = response.previousCursor
                preloadAdjacentImages()
            } catch {

            }
        }
    }

    private func fetchNextRelayCats() {
        guard
            state.nextCursor != nil,
            !state.isLoadingNext,
            let anchorId = state.items.last?.id
        else { return }

        state.isLoadingNext = true

        Task {
            defer { state.isLoadingNext = false }

            let dto = FetchRelayCatsRequestDTO(
                anchorId: anchorId,
                catId: state.catId,
                beforeCount: 0,
                afterCount: 5
            )

            do {
                let response = try await mediaClient.fetchRelayCats(dto)
                let existingIds = Set(state.items.map(\.id))
                let nextItems = response.items.filter {
                    !existingIds.contains($0.id)
                }

                state.items.append(contentsOf: nextItems)
                state.nextCursor = response.nextCursor
                preloadAdjacentImages()
            } catch {

            }
        }
    }

    private func updateIsLiked(id: String, isLiked: Bool) {
        guard let index = state.items.firstIndex(where: { $0.id == id }) else {
            return
        }

        guard state.items[index].isLiked != isLiked else { return }
        state.items[index].isLiked = isLiked

        Task {
            do {
                try await mediaClient.updateIsLiked(id, isLiked)
            } catch {
            }
        }
    }

    private func preloadAdjacentImages() {
        guard
            !state.imageId.isEmpty,
            state.imageSize.width > 0,
            state.imageSize.height > 0,
            state.scale > 0,
            let currentIndex = state.items.firstIndex(where: {
                $0.id == state.imageId
            })
        else { return }

        let urls = [currentIndex - 1, currentIndex + 1]
            .filter(state.items.indices.contains)
            .map { state.items[$0] }
            .filter { $0.mediaType == .photo }
            .compactMap { URL(string: $0.mediaURL) }

        imagePreloadTask?.cancel()

        guard !urls.isEmpty else { return }

        let imageLoaderClient = imageLoaderClient
        let size = state.imageSize
        let scale = state.scale
        
        imagePreloadTask = Task {
            await withTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask {
                        _ = try? await imageLoaderClient.loadImage(
                            url,
                            size,
                            scale,
                            [.memory, .disk, .network]
                        )
                    }
                }
            }
        }
    }
}
