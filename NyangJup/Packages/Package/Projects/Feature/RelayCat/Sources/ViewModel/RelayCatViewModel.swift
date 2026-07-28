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
        var isDeleting = false
        var isCameraPresented: Bool = false
        var editingMediaId: String?
        var isDeleteAlertPresented: Bool = false
        
        var imageId: String = ""
        var imageSize: CGSize = .zero
        var scale: CGFloat = .zero

        init(configuration: RelayCatConfiguration) {
            self.anchorId = configuration.relayCat.mediaId
            self.catId = configuration.relayCat.catId
            self.items = [configuration.relayCat]
            self.currentItemId = configuration.relayCat.mediaId
        }

        var currentItem: RelayCat? {
            items.first { $0.mediaId == currentItemId }
        }

    }

    enum Action {
        case view(View)
        case network(Network)

        enum View {
            case onAppear(CGFloat)
            case itemAppeared(id: String, size: CGSize)
            case editButtonTapped
            case deleteMenuButtonTapped
            case deleteButtonTapped
            case cameraCompleted(Media)
            case cameraDismissed
        }
        
        enum Network {  
            case fetchRelayCats
            case fetchPreviousRelayCats
            case fetchNextRelayCats
            case updateIsLiked(id: String, isLiked: Bool)
            case deleteMedia(id: String)
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

            if id == state.items.first?.mediaId {
                send(.network(.fetchPreviousRelayCats))
            }

            if id == state.items.last?.mediaId {
                send(.network(.fetchNextRelayCats))
            }

        case .editButtonTapped:
            guard let currentItemId = state.currentItemId else {
                return
            }
            state.editingMediaId = currentItemId
            state.isCameraPresented = true
            
        case .deleteMenuButtonTapped:
            state.isDeleteAlertPresented = true

        case .deleteButtonTapped:
            guard let currentItemId = state.currentItemId else {
                return
            }
            send(.network(.deleteMedia(id: currentItemId)))

        case let .cameraCompleted(media):
            replaceEditedItem(with: media)

        case .cameraDismissed:
            state.isCameraPresented = false
            state.editingMediaId = nil
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

        case let .deleteMedia(id):
            deleteMedia(id: id)
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
                    state.currentItemId = response.items[response.anchorIndex].mediaId
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
            let anchorId = state.items.first?.mediaId
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
                let existingIds = Set(state.items.map(\.mediaId))
                let previousItems = response.items.filter {
                    !existingIds.contains($0.mediaId)
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
            let anchorId = state.items.last?.mediaId
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
                let existingIds = Set(state.items.map(\.mediaId))
                let nextItems = response.items.filter {
                    !existingIds.contains($0.mediaId)
                }

                state.items.append(contentsOf: nextItems)
                state.nextCursor = response.nextCursor
                preloadAdjacentImages()
            } catch {

            }
        }
    }

    private func updateIsLiked(id: String, isLiked: Bool) {
        guard let index = state.items.firstIndex(where: { $0.mediaId == id }) else {
            return
        }

        guard state.items[index].isLiked != isLiked else { return }
        let previousIsLiked = state.items[index].isLiked
        state.items[index].isLiked = isLiked

        Task {
            do {
                try await mediaClient.updateIsLiked(id, isLiked)
            } catch {
                guard let index = state.items.firstIndex(where: { $0.mediaId == id }),
                      state.items[index].isLiked == isLiked else {
                    return
                }
                state.items[index].isLiked = previousIsLiked
            }
        }
    }

    private func deleteMedia(id: String) {
        guard !state.isDeleting else { return }
        state.isDeleting = true

        Task {
            defer { state.isDeleting = false }

            do {
                _ = try await mediaClient.deleteMedia(id)
                guard let index = state.items.firstIndex(where: { $0.mediaId == id }) else {
                    return
                }

                let nextItemId: String? = if state.items.indices.contains(index + 1) {
                    state.items[index + 1].mediaId
                } else if index > 0 {
                    state.items[index - 1].mediaId
                } else {
                    nil
                }

                state.items.remove(at: index)
                if state.currentItemId == id {
                    state.currentItemId = nextItemId
                }
                preloadAdjacentImages()
            } catch {

            }
        }
    }

    private func replaceEditedItem(with media: Media) {
        guard let editingMediaId = state.editingMediaId,
              let index = state.items.firstIndex(where: {
                  $0.mediaId == editingMediaId
              }) else {
            return
        }

        let previousItem = state.items[index]
        let updatedItem = RelayCat(
            mediaId: media.id,
            catId: media.catId,
            userId: media.userId,
            comment: media.comment,
            thumbnailURL: media.thumbnailURL,
            name: previousItem.name,
            mediaType: media.mediaType,
            mediaURL: media.mediaURL,
            isLiked: previousItem.isLiked
        )

        state.items[index] = updatedItem
        state.isCameraPresented = false
        state.editingMediaId = nil
        preloadAdjacentImages()
    }

    private func preloadAdjacentImages() {
        guard
            !state.imageId.isEmpty,
            state.imageSize.width > 0,
            state.imageSize.height > 0,
            state.scale > 0,
            let currentIndex = state.items.firstIndex(where: {
                $0.mediaId == state.imageId
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
