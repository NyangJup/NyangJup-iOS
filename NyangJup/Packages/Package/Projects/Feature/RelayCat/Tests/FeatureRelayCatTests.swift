//
//  FeatureRelayCatTests.swift
//  NJPackage
//
//  Created by 정지훈 on 7/22/26.
//

import Testing
import UIKit

import CoreAdsInterface
import CoreImageLoaderInterface
import DomainMediaInterface
import DomainMediaTesting
import FeatureRelayCatInterface
@testable import FeatureRelayCat

private actor RelayCatRequestRecorder {
    private(set) var request: FetchRelayCatsRequestDTO?
    private(set) var requests: [FetchRelayCatsRequestDTO] = []

    func record(_ request: FetchRelayCatsRequestDTO) {
        self.request = request
        self.requests.append(request)
    }
}

private struct ImageLoadRequest: Sendable {
    let url: URL
    let size: CGSize
    let scale: CGFloat
    let options: ImageLoaderClient.CacheOptions
}

private actor ImageLoadRequestRecorder {
    private(set) var requests: [ImageLoadRequest] = []

    func record(_ request: ImageLoadRequest) {
        requests.append(request)
    }
}

private struct LikeUpdateRequest: Equatable, Sendable {
    let id: String
    let isLiked: Bool
}

private actor LikeUpdateRequestRecorder {
    private(set) var requests: [LikeUpdateRequest] = []

    func record(id: String, isLiked: Bool) {
        requests.append(
            LikeUpdateRequest(
                id: id,
                isLiked: isLiked
            )
        )
    }
}

private actor DeletedMediaRecorder {
    private(set) var ids: [String] = []

    func record(id: String) {
        ids.append(id)
    }
}

private actor NativeAdLoadRecorder {
    private(set) var requestedCounts: [Int] = []
    private var batches: [[NativeAdItem]]

    init(batches: [[NativeAdItem]]) {
        self.batches = batches
    }

    func load(count: Int) -> [NativeAdItem] {
        requestedCounts.append(count)
        guard !batches.isEmpty else { return [] }
        return batches.removeFirst()
    }
}

private enum LikeUpdateError: Error {
    case failed
}

private let testImageLoaderClient = ImageLoaderClient { _, _, _, _ in
    UIImage()
}

private let testAdsClient = AdsClient(
    setup: {},
    loadRewardAds: {},
    showRewardAds: { false },
    loadNativeAds: { _ in [] }
)

@MainActor
@Test
func liveFactoryCreatesViewWithRelayCatConfiguration() {
    let relayCat = RelayCat(
        mediaId: "relay-cat",
        catId: "cat-id",
        userId: "test-user-id",
        comment: "",
        thumbnailURL: "https://example.com/thumbnail.jpg",
        name: "나비",
        catImageURL: "https://example.com/cat.png",
        mediaType: .photo,
        mediaURL: "https://example.com/photo.jpg",
        isLiked: false
    )

    _ = RelayCatFactory.live(
        mediaClient: .test,
        imageLoaderClient: testImageLoaderClient,
        adsClient: testAdsClient
    ).makeView(
        RelayCatConfiguration(
            relayCat: relayCat
        ),
        nil
    )
}

@MainActor
@Test
func heartTapOptimisticallyUpdatesItemAndCallsClient() async {
    let relayCat = makeRelayCat(id: "relay-cat")
    let recorder = LikeUpdateRequestRecorder()
    var mediaClient = MediaClient.test
    mediaClient.updateIsLiked = { id, isLiked in
        await recorder.record(id: id, isLiked: isLiked)
    }
    let viewModel = RelayCatViewModel(
        configuration: RelayCatConfiguration(
            relayCat: relayCat
        ),
        mediaClient: mediaClient,
        imageLoaderClient: testImageLoaderClient,
        adsClient: testAdsClient
    )

    viewModel.send(
        .network(
            .updateIsLiked(
                id: relayCat.mediaId,
                isLiked: true
            )
        )
    )

    #expect(viewModel.state.items.first?.isLiked == true)
    await waitForLikeRequests(recorder, count: 1)
    let requests = await recorder.requests
    #expect(
        requests == [
            LikeUpdateRequest(id: relayCat.mediaId, isLiked: true)
        ]
    )
}

@MainActor
@Test
func failedHeartUpdateRestoresPreviousValue() async {
    let relayCat = makeRelayCat(id: "relay-cat")
    let recorder = LikeUpdateRequestRecorder()
    var mediaClient = MediaClient.test
    mediaClient.updateIsLiked = { id, isLiked in
        await recorder.record(id: id, isLiked: isLiked)
        throw LikeUpdateError.failed
    }
    let viewModel = RelayCatViewModel(
        configuration: RelayCatConfiguration(
            relayCat: relayCat
        ),
        mediaClient: mediaClient,
        imageLoaderClient: testImageLoaderClient,
        adsClient: testAdsClient
    )

    viewModel.send(
        .network(
            .updateIsLiked(
                id: relayCat.mediaId,
                isLiked: true
            )
        )
    )

    #expect(viewModel.state.items.first?.isLiked == true)
    await waitForLikeRequests(recorder, count: 1)
    await waitUntil {
        viewModel.state.items.first?.isLiked == relayCat.isLiked
    }

    let requests = await recorder.requests
    #expect(
        requests == [
            LikeUpdateRequest(id: relayCat.mediaId, isLiked: true)
        ]
    )
    #expect(viewModel.state.items.first?.isLiked == false)
}

@MainActor
@Test
func viewModelFetchesRelayCatsOnAppear() async {
    let relayCat = RelayCat(
        mediaId: "relay-cat",
        catId: "cat-id",
        userId: "test-user-id",
        comment: "",
        thumbnailURL: "https://example.com/thumbnail.jpg",
        name: "나비",
        catImageURL: "https://example.com/cat.png",
        mediaType: .video,
        mediaURL: "https://example.com/video.mp4",
        isLiked: false
    )
    let fetchedRelayCat = RelayCat(
        mediaId: "fetched-relay-cat",
        catId: "cat-id",
        userId: "test-user-id",
        comment: "새 콘텐츠",
        thumbnailURL: "https://example.com/fetched-thumbnail.jpg",
        name: "나비",
        catImageURL: "https://example.com/cat.png",
        mediaType: .photo,
        mediaURL: "https://example.com/fetched-photo.jpg",
        isLiked: true
    )
    let serverAnchorRelayCat = RelayCat(
        mediaId: relayCat.mediaId,
        catId: "cat-id",
        userId: "test-user-id",
        comment: "서버 anchor",
        thumbnailURL: "https://example.com/server-thumbnail.jpg",
        name: "나비",
        catImageURL: "https://example.com/cat.png",
        mediaType: .photo,
        mediaURL: "https://example.com/server-photo.jpg",
        isLiked: true
    )
    let recorder = RelayCatRequestRecorder()
    var mediaClient = MediaClient.test
    mediaClient.fetchRelayCats = { request in
        await recorder.record(request)
        return FetchRelayCatsResponseDTO(
            items: [fetchedRelayCat, serverAnchorRelayCat],
            anchorIndex: 1,
            previousCursor: "previous-cursor",
            nextCursor: "next-cursor"
        )
    }
    let viewModel = RelayCatViewModel(
        configuration: RelayCatConfiguration(
            relayCat: relayCat
        ),
        mediaClient: mediaClient,
        imageLoaderClient: testImageLoaderClient,
        adsClient: testAdsClient
    )
    #expect(viewModel.state.anchorId == relayCat.mediaId)
    #expect(viewModel.state.catId == "cat-id")
    #expect(viewModel.state.items == [relayCat])
    #expect(viewModel.state.currentItemId == relayCat.mediaId)

    viewModel.state.currentItemId = nil

    viewModel.send(.view(.onAppear(3)))
    await waitUntil { !viewModel.state.isLoading }

    let request = await recorder.request
    #expect(request?.anchorId == relayCat.mediaId)
    #expect(request?.catId == "cat-id")
    #expect(request?.beforeCount == 5)
    #expect(request?.afterCount == 5)
    #expect(viewModel.state.items == [fetchedRelayCat, serverAnchorRelayCat])
    #expect(viewModel.state.currentItemId == relayCat.mediaId)
    #expect(viewModel.state.previousCursor == "previous-cursor")
    #expect(viewModel.state.nextCursor == "next-cursor")
}

@MainActor
@Test
func viewModelFetchesPreviousAndNextPagesWithoutDuplicates() async {
    let previous = makeRelayCat(id: "previous")
    let first = makeRelayCat(id: "first")
    let last = makeRelayCat(id: "last")
    let next = makeRelayCat(id: "next")
    let recorder = RelayCatRequestRecorder()
    var mediaClient = MediaClient.test
    mediaClient.fetchRelayCats = { request in
        await recorder.record(request)

        if request.beforeCount == 5, request.afterCount == 0 {
            return FetchRelayCatsResponseDTO(
                items: [previous, first],
                anchorIndex: 1,
                previousCursor: nil,
                nextCursor: "unused"
            )
        }

        if request.beforeCount == 0, request.afterCount == 5 {
            return FetchRelayCatsResponseDTO(
                items: [last, next],
                anchorIndex: 0,
                previousCursor: "unused",
                nextCursor: nil
            )
        }

        return FetchRelayCatsResponseDTO(
            items: [first, last],
            anchorIndex: 0,
            previousCursor: "previous-cursor",
            nextCursor: "next-cursor"
        )
    }
    let viewModel = RelayCatViewModel(
        configuration: RelayCatConfiguration(
            relayCat: first
        ),
        mediaClient: mediaClient,
        imageLoaderClient: testImageLoaderClient,
        adsClient: testAdsClient
    )

    viewModel.send(.view(.onAppear(3)))
    await waitUntil { !viewModel.state.isLoading }

    viewModel.send(
        .view(
            .itemAppeared(
                id: first.mediaId,
                size: CGSize(width: 390, height: 844)
            )
        )
    )
    await waitUntil { !viewModel.state.isLoadingPrevious }

    viewModel.send(
        .view(
            .itemAppeared(
                id: last.mediaId,
                size: CGSize(width: 390, height: 844)
            )
        )
    )
    await waitUntil { !viewModel.state.isLoadingNext }

    let requests = await recorder.requests
    #expect(requests.count == 3)
    #expect(requests[1].anchorId == first.mediaId)
    #expect(requests[1].beforeCount == 5)
    #expect(requests[1].afterCount == 0)
    #expect(requests[2].anchorId == last.mediaId)
    #expect(requests[2].beforeCount == 0)
    #expect(requests[2].afterCount == 5)
    #expect(viewModel.state.items == [previous, first, last, next])
    #expect(viewModel.state.previousCursor == nil)
    #expect(viewModel.state.nextCursor == nil)
}

@MainActor
@Test
func nativeAdsAreInsertedAfterEveryThirdItemFromAnchor() async {
    let items = (0..<8).map { makeRelayCat(id: "item-\($0)") }
    let ads = [makeNativeAd(id: "ad-1"), makeNativeAd(id: "ad-2")]
    let recorder = NativeAdLoadRecorder(batches: [ads])
    var mediaClient = MediaClient.test
    mediaClient.fetchRelayCats = { _ in
        FetchRelayCatsResponseDTO(
            items: items,
            anchorIndex: 0,
            previousCursor: nil,
            nextCursor: nil
        )
    }
    let adsClient = AdsClient(
        setup: {},
        loadRewardAds: {},
        showRewardAds: { false },
        loadNativeAds: { count in
            await recorder.load(count: count)
        }
    )
    let viewModel = RelayCatViewModel(
        configuration: RelayCatConfiguration(relayCat: items[0]),
        mediaClient: mediaClient,
        imageLoaderClient: testImageLoaderClient,
        adsClient: adsClient
    )

    viewModel.send(.view(.onAppear(3)))
    await waitUntil { viewModel.state.adSlots.count == 2 }

    #expect(await recorder.requestedCounts == [RelayCatViewModel.nativeAdBatchSize])
    #expect(Set(viewModel.state.adSlots.keys) == ["item-3", "item-6"])
    #expect(viewModel.state.displayItems.map(\.id) == [
        "item-0", "item-1", "item-2", "item-3", "ad-ad-1",
        "item-4", "item-5", "item-6", "ad-ad-2", "item-7"
    ])
}

@MainActor
@Test
func nextPageBoundaryFiltersDuplicateContentAndDoesNotDuplicateAdSlots() async {
    let initialItems = (0..<4).map { makeRelayCat(id: "item-\($0)") }
    let nextItems = (3..<8).map { makeRelayCat(id: "item-\($0)") }
    let firstBatch = [makeNativeAd(id: "ad-1"), makeNativeAd(id: "ad-2")]
    let secondBatch = [makeNativeAd(id: "ad-3"), makeNativeAd(id: "ad-4")]
    let recorder = NativeAdLoadRecorder(batches: [firstBatch, secondBatch])
    var mediaClient = MediaClient.test
    mediaClient.fetchRelayCats = { request in
        if request.beforeCount == 0, request.afterCount == 5 {
            return FetchRelayCatsResponseDTO(
                items: nextItems,
                anchorIndex: 0,
                previousCursor: nil,
                nextCursor: nil
            )
        }

        return FetchRelayCatsResponseDTO(
            items: initialItems,
            anchorIndex: 0,
            previousCursor: nil,
            nextCursor: "next-cursor"
        )
    }
    let adsClient = AdsClient(
        setup: {},
        loadRewardAds: {},
        showRewardAds: { false },
        loadNativeAds: { count in
            await recorder.load(count: count)
        }
    )
    let viewModel = RelayCatViewModel(
        configuration: RelayCatConfiguration(relayCat: initialItems[0]),
        mediaClient: mediaClient,
        imageLoaderClient: testImageLoaderClient,
        adsClient: adsClient
    )

    viewModel.send(.view(.onAppear(3)))
    await waitUntil { !viewModel.state.isLoading && viewModel.state.nextCursor != nil }
    viewModel.send(.view(.itemAppeared(
        id: initialItems[3].mediaId,
        size: CGSize(width: 390, height: 844)
    )))
    await waitUntil { !viewModel.state.isLoadingNext && viewModel.state.adSlots.count == 2 }

    #expect(viewModel.state.items.map(\.mediaId) == (0..<8).map { "item-\($0)" })
    #expect(Set(viewModel.state.adSlots.keys) == ["item-3", "item-6"])
    #expect(Set(viewModel.state.displayItems.map(\.id)).count == viewModel.state.displayItems.count)
}

@MainActor
@Test
func adSelectionHasNoMenuItemAndIgnoresEditAndDelete() async {
    let relayCat = makeRelayCat(id: "relay-cat")
    let ad = makeNativeAd(id: "ad-1")
    let deleteRecorder = DeletedMediaRecorder()
    var mediaClient = MediaClient.test
    mediaClient.deleteMedia = { id in
        await deleteRecorder.record(id: id)
        return Media(
            id: id,
            catId: relayCat.catId,
            userId: relayCat.userId,
            comment: relayCat.comment,
            thumbnailURL: relayCat.thumbnailURL,
            mediaType: relayCat.mediaType,
            mediaURL: relayCat.mediaURL
        )
    }
    let viewModel = RelayCatViewModel(
        configuration: RelayCatConfiguration(relayCat: relayCat),
        mediaClient: mediaClient,
        imageLoaderClient: testImageLoaderClient,
        adsClient: testAdsClient
    )
    viewModel.state.adSlots[relayCat.mediaId] = ad
    viewModel.state.currentItemId = RelayCatFeedItem.ad(ad).id

    #expect(viewModel.state.currentItem == nil)
    viewModel.send(.view(.editButtonTapped))
    viewModel.send(.view(.deleteButtonTapped))
    await Task.yield()

    #expect(!viewModel.state.isCameraPresented)
    #expect(viewModel.state.editingMediaId == nil)
    #expect(await deleteRecorder.ids.isEmpty)
}

@MainActor
@Test
func viewModelPreloadsAdjacentPhotosAfterInitialResponse() async {
    let previous = makeRelayCat(id: "previous")
    let anchor = RelayCat(
        mediaId: "anchor",
        catId: "cat-id",
        userId: "test-user-id",
        comment: "",
        thumbnailURL: "https://example.com/anchor-thumbnail.jpg",
        name: "나비",
        catImageURL: "https://example.com/cat.png",
        mediaType: .video,
        mediaURL: "https://example.com/anchor.m3u8",
        isLiked: false
    )
    let next = makeRelayCat(id: "next")
    let recorder = ImageLoadRequestRecorder()
    let imageLoaderClient = ImageLoaderClient { url, size, scale, options in
        await recorder.record(
            ImageLoadRequest(
                url: url,
                size: size,
                scale: scale,
                options: options
            )
        )
        return UIImage()
    }
    var mediaClient = MediaClient.test
    mediaClient.fetchRelayCats = { _ in
        FetchRelayCatsResponseDTO(
            items: [previous, anchor, next],
            anchorIndex: 1,
            previousCursor: nil,
            nextCursor: nil
        )
    }
    let viewModel = RelayCatViewModel(
        configuration: RelayCatConfiguration(
            relayCat: anchor
        ),
        mediaClient: mediaClient,
        imageLoaderClient: imageLoaderClient,
        adsClient: testAdsClient
    )
    let imageSize = CGSize(width: 390, height: 844)

    viewModel.send(
        .view(
            .itemAppeared(
                id: anchor.mediaId,
                size: imageSize
            )
        )
    )
    viewModel.send(.view(.onAppear(3)))

    await waitUntil { !viewModel.state.isLoading }
    await waitForImageRequests(recorder, count: 2)

    let requests = await recorder.requests
    #expect(Set(requests.map(\.url)) == Set([
        URL(string: previous.mediaURL)!,
        URL(string: next.mediaURL)!
    ]))
    #expect(requests.allSatisfy { $0.size == imageSize })
    #expect(requests.allSatisfy { $0.scale == 3 })
    #expect(requests.allSatisfy {
        $0.options == [.memory, .disk, .network]
    })
}

@MainActor
@Test
func viewModelDoesNotPreloadAdjacentVideo() async {
    let previous = makeRelayCat(id: "previous")
    let anchor = makeRelayCat(id: "anchor")
    let nextVideo = RelayCat(
        mediaId: "next-video",
        catId: "cat-id",
        userId: "test-user-id",
        comment: "",
        thumbnailURL: "https://example.com/next-video-thumbnail.jpg",
        name: "나비",
        catImageURL: "https://example.com/cat.png",
        mediaType: .video,
        mediaURL: "https://example.com/next-video.m3u8",
        isLiked: false
    )
    let recorder = ImageLoadRequestRecorder()
    let imageLoaderClient = ImageLoaderClient { url, size, scale, options in
        await recorder.record(
            ImageLoadRequest(
                url: url,
                size: size,
                scale: scale,
                options: options
            )
        )
        return UIImage()
    }
    var mediaClient = MediaClient.test
    mediaClient.fetchRelayCats = { _ in
        FetchRelayCatsResponseDTO(
            items: [],
            anchorIndex: 0,
            previousCursor: nil,
            nextCursor: nil
        )
    }
    let viewModel = RelayCatViewModel(
        configuration: RelayCatConfiguration(
            relayCat: anchor
        ),
        mediaClient: mediaClient,
        imageLoaderClient: imageLoaderClient,
        adsClient: testAdsClient
    )
    viewModel.state.items = [previous, anchor, nextVideo]

    viewModel.send(.view(.onAppear(3)))
    viewModel.send(
        .view(
            .itemAppeared(
                id: anchor.mediaId,
                size: CGSize(width: 390, height: 844)
            )
        )
    )

    await waitForImageRequests(recorder, count: 1)

    let requests = await recorder.requests
    #expect(requests.map(\.url) == [URL(string: previous.mediaURL)!])
}

@MainActor
@Test
func viewModelPreloadsPhotosAddedByPreviousAndNextPages() async {
    let newPrevious = makeRelayCat(id: "new-previous")
    let first = makeVideoRelayCat(id: "first")
    let last = makeVideoRelayCat(id: "last")
    let newNext = makeRelayCat(id: "new-next")
    let recorder = ImageLoadRequestRecorder()
    let imageLoaderClient = ImageLoaderClient { url, size, scale, options in
        await recorder.record(
            ImageLoadRequest(
                url: url,
                size: size,
                scale: scale,
                options: options
            )
        )
        return UIImage()
    }
    var mediaClient = MediaClient.test
    mediaClient.fetchRelayCats = { request in
        if request.beforeCount == 5, request.afterCount == 0 {
            return FetchRelayCatsResponseDTO(
                items: [newPrevious, first],
                anchorIndex: 1,
                previousCursor: nil,
                nextCursor: "unused"
            )
        }

        if request.beforeCount == 0, request.afterCount == 5 {
            return FetchRelayCatsResponseDTO(
                items: [last, newNext],
                anchorIndex: 0,
                previousCursor: "unused",
                nextCursor: nil
            )
        }

        return FetchRelayCatsResponseDTO(
            items: [],
            anchorIndex: 0,
            previousCursor: nil,
            nextCursor: nil
        )
    }
    let viewModel = RelayCatViewModel(
        configuration: RelayCatConfiguration(
            relayCat: first
        ),
        mediaClient: mediaClient,
        imageLoaderClient: imageLoaderClient,
        adsClient: testAdsClient
    )
    let imageSize = CGSize(width: 390, height: 844)

    viewModel.send(.view(.onAppear(3)))
    await waitUntil { !viewModel.state.isLoading }

    viewModel.state.items = [first, last]
    viewModel.state.previousCursor = "previous-cursor"
    viewModel.state.nextCursor = "next-cursor"

    viewModel.send(
        .view(
            .itemAppeared(
                id: first.mediaId,
                size: imageSize
            )
        )
    )
    await waitUntil { !viewModel.state.isLoadingPrevious }
    await waitForImageRequests(recorder, count: 1)

    viewModel.send(
        .view(
            .itemAppeared(
                id: last.mediaId,
                size: imageSize
            )
        )
    )
    await waitUntil { !viewModel.state.isLoadingNext }
    await waitForImageRequests(recorder, count: 2)

    let requests = await recorder.requests
    #expect(Set(requests.map(\.url)) == Set([
        URL(string: newPrevious.mediaURL)!,
        URL(string: newNext.mediaURL)!
    ]))
}

@MainActor
@Test
func editingCurrentItemWithCaptureResultReplacesIt() {
    let relayCat = makeOwnedRelayCat(id: "owned", userId: "current-user")
    let viewModel = RelayCatViewModel(
        configuration: RelayCatConfiguration(
            relayCat: relayCat
        ),
        mediaClient: .test,
        imageLoaderClient: testImageLoaderClient,
        adsClient: testAdsClient
    )
    viewModel.send(.view(.editButtonTapped))

    #expect(viewModel.state.isCameraPresented)
    #expect(viewModel.state.editingMediaId == relayCat.mediaId)

    viewModel.send(.view(.cameraCompleted(
        Media(
            id: relayCat.mediaId,
            catId: relayCat.catId,
            userId: relayCat.userId,
            comment: "수정된 메모",
            thumbnailURL: "https://example.com/updated-thumbnail.jpg",
            mediaType: .video,
            mediaURL: "https://example.com/updated.mp4"
        )
    )))

    #expect(viewModel.state.items.count == 1)
    #expect(viewModel.state.currentItem?.comment == "수정된 메모")
    #expect(viewModel.state.currentItem?.mediaType == .video)
    #expect(viewModel.state.currentItem?.mediaURL == "https://example.com/updated.mp4")
    #expect(viewModel.state.currentItem?.catImageURL == relayCat.catImageURL)
    #expect(viewModel.state.currentItemId == relayCat.mediaId)
    #expect(!viewModel.state.isCameraPresented)
    #expect(viewModel.state.editingMediaId == nil)
}

@MainActor
@Test
func deletingCurrentItemSelectsNextItem() async {
    let current = makeOwnedRelayCat(id: "current", userId: "current-user")
    let next = makeOwnedRelayCat(id: "next", userId: "other-user")
    let recorder = DeletedMediaRecorder()
    var mediaClient = MediaClient.test
    mediaClient.deleteMedia = { id in
        await recorder.record(id: id)
        return Media(
            id: id,
            catId: "cat-id",
            userId: "test-user-id",
            comment: "",
            thumbnailURL: "",
            mediaType: .photo,
            mediaURL: ""
        )
    }
    let viewModel = RelayCatViewModel(
        configuration: RelayCatConfiguration(
            relayCat: current
        ),
        mediaClient: mediaClient,
        imageLoaderClient: testImageLoaderClient,
        adsClient: testAdsClient
    )
    viewModel.state.items = [current, next]

    viewModel.send(.view(.deleteButtonTapped))
    await waitUntil { !viewModel.state.isDeleting }

    let deletedIds = await recorder.ids
    #expect(deletedIds == [current.mediaId])
    #expect(viewModel.state.items == [next])
    #expect(viewModel.state.currentItemId == next.mediaId)
}

@MainActor
@Test
func deletingLastItemSelectsPreviousItem() async {
    let previous = makeRelayCat(id: "previous")
    let current = makeRelayCat(id: "current")
    var mediaClient = MediaClient.test
    mediaClient.deleteMedia = { id in
        Media(
            id: id,
            catId: current.catId,
            userId: current.userId,
            comment: current.comment,
            thumbnailURL: current.thumbnailURL,
            mediaType: current.mediaType,
            mediaURL: current.mediaURL
        )
    }
    let viewModel = RelayCatViewModel(
        configuration: RelayCatConfiguration(relayCat: current),
        mediaClient: mediaClient,
        imageLoaderClient: testImageLoaderClient,
        adsClient: testAdsClient
    )
    viewModel.state.items = [previous, current]

    viewModel.send(.view(.deleteButtonTapped))
    await waitUntil { !viewModel.state.isDeleting }

    #expect(viewModel.state.items == [previous])
    #expect(viewModel.state.currentItemId == previous.mediaId)
}

@MainActor
@Test
func deletingOnlyItemClearsCurrentSelection() async {
    let current = makeRelayCat(id: "current")
    var mediaClient = MediaClient.test
    mediaClient.deleteMedia = { id in
        Media(
            id: id,
            catId: current.catId,
            userId: current.userId,
            comment: current.comment,
            thumbnailURL: current.thumbnailURL,
            mediaType: current.mediaType,
            mediaURL: current.mediaURL
        )
    }
    let viewModel = RelayCatViewModel(
        configuration: RelayCatConfiguration(relayCat: current),
        mediaClient: mediaClient,
        imageLoaderClient: testImageLoaderClient,
        adsClient: testAdsClient
    )

    viewModel.send(.view(.deleteButtonTapped))
    await waitUntil { !viewModel.state.isDeleting }

    #expect(viewModel.state.items.isEmpty)
    #expect(viewModel.state.currentItemId == nil)
}

@MainActor
@Test
func cancellingDeleteAlertDoesNotRequestDeletion() async {
    let current = makeRelayCat(id: "current")
    let recorder = DeletedMediaRecorder()
    var mediaClient = MediaClient.test
    mediaClient.deleteMedia = { id in
        await recorder.record(id: id)
        return Media(
            id: id,
            catId: current.catId,
            userId: current.userId,
            comment: current.comment,
            thumbnailURL: current.thumbnailURL,
            mediaType: current.mediaType,
            mediaURL: current.mediaURL
        )
    }
    let viewModel = RelayCatViewModel(
        configuration: RelayCatConfiguration(relayCat: current),
        mediaClient: mediaClient,
        imageLoaderClient: testImageLoaderClient,
        adsClient: testAdsClient
    )

    viewModel.send(.view(.deleteMenuButtonTapped))
    #expect(viewModel.state.isDeleteAlertPresented)

    viewModel.state.isDeleteAlertPresented = false
    await Task.yield()

    #expect(await recorder.ids.isEmpty)
    #expect(viewModel.state.items == [current])
    #expect(viewModel.state.currentItemId == current.mediaId)
}

private func makeRelayCat(id: String) -> RelayCat {
    RelayCat(
        mediaId: id,
        catId: "cat-id",
        userId: "test-user-id",
        comment: "",
        thumbnailURL: "https://example.com/\(id)-thumbnail.jpg",
        name: "나비",
        catImageURL: "https://example.com/\(id)-cat.png",
        mediaType: .photo,
        mediaURL: "https://example.com/\(id).jpg",
        isLiked: false
    )
}

private func makeNativeAd(id: String) -> NativeAdItem {
    NativeAdItem(id: id, object: NSObject())
}

private func makeOwnedRelayCat(id: String, userId: String) -> RelayCat {
    RelayCat(
        mediaId: id,
        catId: "cat-id",
        userId: userId,
        comment: "",
        thumbnailURL: "https://example.com/\(id)-thumbnail.jpg",
        name: "나비",
        catImageURL: "https://example.com/\(id)-cat.png",
        mediaType: .photo,
        mediaURL: "https://example.com/\(id).jpg",
        isLiked: false
    )
}

private func makeVideoRelayCat(id: String) -> RelayCat {
    RelayCat(
        mediaId: id,
        catId: "cat-id",
        userId: "test-user-id",
        comment: "",
        thumbnailURL: "https://example.com/\(id)-thumbnail.jpg",
        name: "나비",
        catImageURL: "https://example.com/\(id)-cat.png",
        mediaType: .video,
        mediaURL: "https://example.com/\(id).m3u8",
        isLiked: false
    )
}

@MainActor
private func waitUntil(_ condition: () -> Bool) async {
    for _ in 0..<100 {
        if condition() { return }
        await Task.yield()
    }
}

private func waitForImageRequests(
    _ recorder: ImageLoadRequestRecorder,
    count: Int
) async {
    for _ in 0..<100 {
        if await recorder.requests.count == count { return }
        try? await Task.sleep(for: .milliseconds(1))
    }
}

private func waitForLikeRequests(
    _ recorder: LikeUpdateRequestRecorder,
    count: Int
) async {
    for _ in 0..<100 {
        if await recorder.requests.count == count { return }
        try? await Task.sleep(for: .milliseconds(1))
    }
}
