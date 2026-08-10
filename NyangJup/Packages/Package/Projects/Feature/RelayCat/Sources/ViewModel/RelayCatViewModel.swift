//
//  RelayCatViewModel.swift
//  NJPackage
//
//  Created by 정지훈 on 7/22/26.
//

import Foundation

import CoreAdsInterface
import CoreImageLoaderInterface
import DomainMediaInterface
import FeatureCommonInterface
import FeatureRelayCatInterface

@MainActor
@Observable
final class RelayCatViewModel: NZViewModel {

    nonisolated static let adInsertInterval = 3
    nonisolated static let nativeAdBatchSize = 2

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
        
        /// 아직 배치되지 않은 광고 재고
        var ads: [NativeAdItem] = []
        /// mediaId → 그 콘텐츠 "뒤"에 붙을 광고. 한 번 정하면 바꾸지 않는다
        var adSlots: [String: NativeAdItem] = [:]

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

        var displayItems: [RelayCatFeedItem] {
            var result: [RelayCatFeedItem] = []

            for item in items {
                result.append(.relay(item))

                if let ad = adSlots[item.mediaId] {
                    result.append(.ad(ad))
                }
            }

            return result
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
            case loadNativeAds
        }
    }

    var state: State
    private let mediaClient: MediaClient
    private let imageLoaderClient: ImageLoaderClient
    private let adsClient: AdsClient
    private var imagePreloadTask: Task<Void, Never>?

    init(
        configuration: RelayCatConfiguration,
        mediaClient: MediaClient,
        imageLoaderClient: ImageLoaderClient,
        adsClient: AdsClient
    ) {
        self.state = State(configuration: configuration)
        self.mediaClient = mediaClient
        self.imageLoaderClient = imageLoaderClient
        self.adsClient = adsClient
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
            // 광고 페이지에서는 currentItem이 nil이라 자연히 막힌다
            guard let currentItem = state.currentItem else {
                return
            }
            state.editingMediaId = currentItem.mediaId
            state.isCameraPresented = true
            
        case .deleteMenuButtonTapped:
            state.isDeleteAlertPresented = true

        case .deleteButtonTapped:
            guard let currentItem = state.currentItem else {
                return
            }
            send(.network(.deleteMedia(id: currentItem.mediaId)))

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

        case .loadNativeAds:
            loadNativeAds()
        }
    }

    /// 재고가 비었을 때만 보충한다.
    /// 콘텐츠를 새로 받아온 직후에만 호출되므로 콘텐츠 없이 광고만 쌓이지 않는다.
    private func loadNativeAdsIfNeeded() {
        guard state.ads.isEmpty else { return }
        send(.network(.loadNativeAds))
    }

    private func loadNativeAds() {
        Task {
            do {
                let ads = try await adsClient.loadNativeAds(Self.nativeAdBatchSize)
                guard !ads.isEmpty else { return }

                state.ads.append(contentsOf: ads)
                assignAdSlots()
            } catch {

            }
        }
    }

    /// anchor로부터의 거리로 광고 자리를 정한다.
    /// 앞쪽에 콘텐츠가 끼어들어도 기존 배치는 유지된다.
    private func assignAdSlots() {
        guard let anchorIndex = state.items.firstIndex(
            where: { $0.mediaId == state.anchorId }
        ) else { return }

        for (index, item) in state.items.enumerated() {
            // 재고가 없으면 남은 자리는 비워둔다
            guard !state.ads.isEmpty else { break }

            // 이미 자리가 정해졌으면 건드리지 않는다
            guard state.adSlots[item.mediaId] == nil else { continue }

            // 마지막 콘텐츠 뒤에는 붙이지 않는다
            guard index != state.items.count - 1 else { continue }

            let distance = index - anchorIndex

            guard distance != 0,
                  distance % Self.adInsertInterval == 0
            else { continue }

            state.adSlots[item.mediaId] = state.ads.removeFirst()
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

                assignAdSlots()
                loadNativeAdsIfNeeded()
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
                assignAdSlots()
                loadNativeAdsIfNeeded()
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
                assignAdSlots()
                loadNativeAdsIfNeeded()
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
