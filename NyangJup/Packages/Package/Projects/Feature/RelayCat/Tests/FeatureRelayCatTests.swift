//
//  FeatureRelayCatTests.swift
//  NJPackage
//
//  Created by 정지훈 on 7/22/26.
//

import Testing
import UIKit

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

private enum LikeUpdateError: Error {
    case failed
}

private let testImageLoaderClient = ImageLoaderClient { _, _, _, _ in
    UIImage()
}

@MainActor
@Test
func liveFactoryCreatesViewWithRelayCatConfiguration() {
    let relayCat = RelayCat(
        id: "relay-cat",
        memo: "",
        thumbnailURL: "https://example.com/thumbnail.jpg",
        name: "나비",
        mediaType: .photo,
        mediaURL: "https://example.com/photo.jpg",
        isLiked: false
    )

    _ = RelayCatFactory.live(
        mediaClient: .test,
        imageLoaderClient: testImageLoaderClient
    ).makeView(
        RelayCatConfiguration(
            relayCat: relayCat,
            catId: "cat-id"
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
            relayCat: relayCat,
            catId: "cat-id"
        ),
        mediaClient: mediaClient,
        imageLoaderClient: testImageLoaderClient
    )

    viewModel.send(
        .network(
            .updateIsLiked(
                id: relayCat.id,
                isLiked: true
            )
        )
    )

    #expect(viewModel.state.items.first?.isLiked == true)
    await waitForLikeRequests(recorder, count: 1)
    let requests = await recorder.requests
    #expect(
        requests == [
            LikeUpdateRequest(id: relayCat.id, isLiked: true)
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
            relayCat: relayCat,
            catId: "cat-id"
        ),
        mediaClient: mediaClient,
        imageLoaderClient: testImageLoaderClient
    )

    viewModel.send(
        .network(
            .updateIsLiked(
                id: relayCat.id,
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
            LikeUpdateRequest(id: relayCat.id, isLiked: true)
        ]
    )
    #expect(viewModel.state.items.first?.isLiked == false)
}

@MainActor
@Test
func viewModelFetchesRelayCatsOnAppear() async {
    let relayCat = RelayCat(
        id: "relay-cat",
        memo: "",
        thumbnailURL: "https://example.com/thumbnail.jpg",
        name: "나비",
        mediaType: .video,
        mediaURL: "https://example.com/video.mp4",
        isLiked: false
    )
    let fetchedRelayCat = RelayCat(
        id: "fetched-relay-cat",
        memo: "새 콘텐츠",
        thumbnailURL: "https://example.com/fetched-thumbnail.jpg",
        name: "나비",
        mediaType: .photo,
        mediaURL: "https://example.com/fetched-photo.jpg",
        isLiked: true
    )
    let serverAnchorRelayCat = RelayCat(
        id: relayCat.id,
        memo: "서버 anchor",
        thumbnailURL: "https://example.com/server-thumbnail.jpg",
        name: "나비",
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
            relayCat: relayCat,
            catId: "cat-id"
        ),
        mediaClient: mediaClient,
        imageLoaderClient: testImageLoaderClient
    )
    #expect(viewModel.state.anchorId == relayCat.id)
    #expect(viewModel.state.catId == "cat-id")
    #expect(viewModel.state.items == [relayCat])
    #expect(viewModel.state.currentItemId == relayCat.id)

    viewModel.state.currentItemId = nil

    viewModel.send(.view(.onAppear(3)))
    await waitUntil { !viewModel.state.isLoading }

    let request = await recorder.request
    #expect(request?.anchorId == relayCat.id)
    #expect(request?.catId == "cat-id")
    #expect(request?.beforeCount == 5)
    #expect(request?.afterCount == 5)
    #expect(viewModel.state.items == [fetchedRelayCat, serverAnchorRelayCat])
    #expect(viewModel.state.currentItemId == relayCat.id)
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
            relayCat: first,
            catId: "cat-id"
        ),
        mediaClient: mediaClient,
        imageLoaderClient: testImageLoaderClient
    )

    viewModel.send(.view(.onAppear(3)))
    await waitUntil { !viewModel.state.isLoading }

    viewModel.send(
        .view(
            .itemAppeared(
                id: first.id,
                size: CGSize(width: 390, height: 844)
            )
        )
    )
    await waitUntil { !viewModel.state.isLoadingPrevious }

    viewModel.send(
        .view(
            .itemAppeared(
                id: last.id,
                size: CGSize(width: 390, height: 844)
            )
        )
    )
    await waitUntil { !viewModel.state.isLoadingNext }

    let requests = await recorder.requests
    #expect(requests.count == 3)
    #expect(requests[1].anchorId == first.id)
    #expect(requests[1].beforeCount == 5)
    #expect(requests[1].afterCount == 0)
    #expect(requests[2].anchorId == last.id)
    #expect(requests[2].beforeCount == 0)
    #expect(requests[2].afterCount == 5)
    #expect(viewModel.state.items == [previous, first, last, next])
    #expect(viewModel.state.previousCursor == nil)
    #expect(viewModel.state.nextCursor == nil)
}

@MainActor
@Test
func viewModelPreloadsAdjacentPhotosAfterInitialResponse() async {
    let previous = makeRelayCat(id: "previous")
    let anchor = RelayCat(
        id: "anchor",
        memo: "",
        thumbnailURL: "https://example.com/anchor-thumbnail.jpg",
        name: "나비",
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
            relayCat: anchor,
            catId: "cat-id"
        ),
        mediaClient: mediaClient,
        imageLoaderClient: imageLoaderClient
    )
    let imageSize = CGSize(width: 390, height: 844)

    viewModel.send(
        .view(
            .itemAppeared(
                id: anchor.id,
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
        id: "next-video",
        memo: "",
        thumbnailURL: "https://example.com/next-video-thumbnail.jpg",
        name: "나비",
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
            relayCat: anchor,
            catId: "cat-id"
        ),
        mediaClient: mediaClient,
        imageLoaderClient: imageLoaderClient
    )
    viewModel.state.items = [previous, anchor, nextVideo]

    viewModel.send(.view(.onAppear(3)))
    viewModel.send(
        .view(
            .itemAppeared(
                id: anchor.id,
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
            relayCat: first,
            catId: "cat-id"
        ),
        mediaClient: mediaClient,
        imageLoaderClient: imageLoaderClient
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
                id: first.id,
                size: imageSize
            )
        )
    )
    await waitUntil { !viewModel.state.isLoadingPrevious }
    await waitForImageRequests(recorder, count: 1)

    viewModel.send(
        .view(
            .itemAppeared(
                id: last.id,
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

private func makeRelayCat(id: String) -> RelayCat {
    RelayCat(
        id: id,
        memo: "",
        thumbnailURL: "https://example.com/\(id)-thumbnail.jpg",
        name: "나비",
        mediaType: .photo,
        mediaURL: "https://example.com/\(id).jpg",
        isLiked: false
    )
}

private func makeVideoRelayCat(id: String) -> RelayCat {
    RelayCat(
        id: id,
        memo: "",
        thumbnailURL: "https://example.com/\(id)-thumbnail.jpg",
        name: "나비",
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
