//
//  FeatureHomeTests.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import Testing
import SpriteKit

import DomainCatsInterface
import DomainCatsTesting
import DomainMediaInterface
import DomainMediaTesting
import DomainProfileTesting
import FeatureCommonInterface
import FeatureHomeInterface
@testable import FeatureHome

@MainActor
private final class HomeCoordinatorSpy: Coordinator {
    typealias Route = HomeRoute

    var routes: [HomeRoute] = []

    func push(to route: HomeRoute) {
        routes.append(route)
    }

    func pop() {
        _ = routes.popLast()
    }
}

private actor CreateCatRequestRecorder {
    private(set) var request: CreateCatRequestDTO?

    func record(_ request: CreateCatRequestDTO) {
        self.request = request
    }
}

private actor FetchCatsGate {
    private var continuation: CheckedContinuation<Void, Never>?

    var isWaiting: Bool {
        continuation != nil
    }

    func wait() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }
}

private actor FeedRequestRecorder {
    private(set) var cursors: [String?] = []

    func record(cursor: String?) {
        cursors.append(cursor)
    }
}

private enum TestError: Error {
    case createCatFailed
    case fetchFeedsFailed
}

@MainActor
@Test
func syncingCatsKeepsExistingCatNodeAndAddsMissingCat() {
    let existingCat = Cat(
        id: "existing-cat",
        name: "나비",
        place: "집",
        appearanceKey: "abyssinian"
    )
    let addedCat = Cat(
        id: "added-cat",
        name: "냥이",
        place: "집",
        appearanceKey: "abyssinian"
    )
    let scene = HomeMapScene(
        size: CGSize(width: 390, height: 844),
        cats: [existingCat],
        onCatTapped: { _, _ in },
        onSelectionCleared: {}
    )!
    scene.didMove(to: SKView())

    let existingNode = scene.children.first {
        $0.userData?["catID"] as? String == existingCat.id
    }
    let existingPosition = existingNode?.position

    scene.syncCats([existingCat, addedCat])

    let updatedExistingNode = scene.children.first {
        $0.userData?["catID"] as? String == existingCat.id
    }
    let addedNode = scene.children.first {
        $0.userData?["catID"] as? String == addedCat.id
    }

    #expect(updatedExistingNode === existingNode)
    #expect(updatedExistingNode?.position == existingPosition)
    #expect(addedNode != nil)
}

@MainActor
@Test
func syncingCatsRemovesCatMissingFromState() {
    let removedCat = Cat(
        id: "removed-cat",
        name: "나비",
        place: "집",
        appearanceKey: "abyssinian"
    )
    let remainingCat = Cat(
        id: "remaining-cat",
        name: "냥이",
        place: "집",
        appearanceKey: "abyssinian"
    )
    let scene = HomeMapScene(
        size: CGSize(width: 390, height: 844),
        cats: [removedCat, remainingCat],
        onCatTapped: { _, _ in },
        onSelectionCleared: {}
    )!
    scene.didMove(to: SKView())

    scene.syncCats([remainingCat])

    let removedNode = scene.children.first {
        $0.userData?["catID"] as? String == removedCat.id
    }
    let remainingNode = scene.children.first {
        $0.userData?["catID"] as? String == remainingCat.id
    }
    #expect(removedNode == nil)
    #expect(remainingNode != nil)
}

@MainActor
@Test
func movingSceneTwiceDoesNotDuplicateCats() {
    let cat = Cat(
        id: "existing-cat",
        name: "나비",
        place: "집",
        appearanceKey: "abyssinian"
    )
    let scene = HomeMapScene(
        size: CGSize(width: 390, height: 844),
        cats: [cat],
        onCatTapped: { _, _ in },
        onSelectionCleared: {}
    )!

    scene.didMove(to: SKView())
    scene.didMove(to: SKView())

    let catNodes = scene.children.filter {
        $0.userData?["catID"] as? String == cat.id
    }
    #expect(catNodes.count == 1)
}

@MainActor
@Test
func sceneIsNotCreatedWithInvalidMovementRange() {
    let scene = HomeMapScene(
        size: CGSize(width: 79, height: 159),
        cats: [],
        onCatTapped: { _, _ in },
        onSelectionCleared: {}
    )

    #expect(scene == nil)
}

@MainActor
@Test
func plusButtonPresentsMakeCat() {
    let coordinator = HomeCoordinatorSpy()
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        coordinator: coordinator
    )
    viewModel.state.selectedCatId = "selected-cat"

    #expect(viewModel.state.isMakeCatPresented == false)
    viewModel.send(.view(.plusButtonTapped))
    #expect(viewModel.state.isMakeCatPresented == true)
    #expect(viewModel.state.selectedCatId == nil)
}

@MainActor
@Test
func catTappedSelectsCat() {
    let selectedCat = Cat(
        id: "selected-cat",
        name: "나비",
        place: "집",
        appearanceKey: "abyssinian"
    )
    let coordinator = HomeCoordinatorSpy()
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        coordinator: coordinator
    )
    viewModel.state.cats = [selectedCat]

    viewModel.send(.view(.catTapped(id: selectedCat.id)))

    #expect(viewModel.state.selectedCatId == selectedCat.id)
    #expect(viewModel.state.selectedCat?.id == selectedCat.id)
}

@MainActor
@Test
func selectionClearedClearsSelectedCat() {
    let coordinator = HomeCoordinatorSpy()
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        coordinator: coordinator
    )
    viewModel.state.selectedCatId = "selected-cat"

    viewModel.send(.view(.selectionCleared))

    #expect(viewModel.state.selectedCatId == nil)
}

@MainActor
@Test
func speechBubblePushesSelectedCatFeedRoute() {
    let coordinator = HomeCoordinatorSpy()
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        coordinator: coordinator
    )
    viewModel.state.selectedCatId = "selected-cat"

    viewModel.send(.view(.speechBubbleTapped))

    #expect(coordinator.routes == [.feed(catId: "selected-cat")])
}

@MainActor
@Test
func makeCatSubmittedAddsCreatedCatAndDismissesSheet() async {
    let coordinator = HomeCoordinatorSpy()
    let recorder = CreateCatRequestRecorder()
    var catsClient = CatsClient.test
    catsClient.createCat = { request in
        await recorder.record(request)
        return Cat(
            id: "created-cat",
            name: request.name,
            place: "",
            appearanceKey: request.appearanceKey
        )
    }
    let viewModel = HomeViewModel(
        catsClient: catsClient,
        profileClient: .test,
        coordinator: coordinator
    )
    viewModel.send(.view(.plusButtonTapped))

    viewModel.send(.view(.makeCatSubmitted(
        name: "나비",
        appearanceKey: "abyssinian"
    )))

    await waitUntil { viewModel.state.cats.count == 1 }
    let request = await recorder.request
    #expect(request?.name == "나비")
    #expect(request?.appearanceKey == "abyssinian")
    #expect(viewModel.state.cats.first?.name == "나비")
    #expect(viewModel.state.cats.first?.appearanceKey == "abyssinian")
    #expect(viewModel.state.isMakeCatPresented == false)
}

@MainActor
@Test
func lateFetchKeepsCatCreatedWhileRequestWasInFlight() async {
    let localCat = Cat(
        id: "local-cat",
        name: "나비",
        place: "집",
        appearanceKey: "abyssinian"
    )
    let fetchedCat = Cat(
        id: "fetched-cat",
        name: "냥이",
        place: "집",
        appearanceKey: "abyssinian"
    )
    let gate = FetchCatsGate()
    var catsClient = CatsClient.test
    catsClient.fetchCats = { _ in
        await gate.wait()
        return [
            Cat(
                id: "fetched-cat",
                name: "냥이",
                place: "집",
                appearanceKey: "abyssinian"
            )
        ]
    }
    catsClient.createCat = { _ in
        Cat(
            id: "local-cat",
            name: "나비",
            place: "집",
            appearanceKey: "abyssinian"
        )
    }
    let viewModel = HomeViewModel(
        catsClient: catsClient,
        profileClient: .test,
        coordinator: HomeCoordinatorSpy()
    )

    viewModel.send(.view(.onAppear))
    for _ in 0..<100 {
        if await gate.isWaiting { break }
        await Task.yield()
    }
    viewModel.send(.view(.makeCatSubmitted(
        name: localCat.name,
        appearanceKey: localCat.appearanceKey
    )))
    await waitUntil { viewModel.state.cats.contains { $0.id == localCat.id } }

    await gate.resume()
    await waitUntil { viewModel.state.cats.count == 2 }

    #expect(viewModel.state.cats.map(\.id) == [fetchedCat.id, localCat.id])
}

@MainActor
@Test
func makeCatSubmittedFailureKeepsSheetPresented() async {
    let coordinator = HomeCoordinatorSpy()
    let recorder = CreateCatRequestRecorder()
    var catsClient = CatsClient.test
    catsClient.createCat = { request in
        await recorder.record(request)
        throw TestError.createCatFailed
    }
    let viewModel = HomeViewModel(
        catsClient: catsClient,
        profileClient: .test,
        coordinator: coordinator
    )
    viewModel.send(.view(.plusButtonTapped))

    viewModel.send(.view(.makeCatSubmitted(
        name: "나비",
        appearanceKey: "abyssinian"
    )))

    for _ in 0..<100 {
        if await recorder.request != nil { break }
        await Task.yield()
    }
    #expect(await recorder.request != nil)
    #expect(viewModel.state.cats.isEmpty)
    #expect(viewModel.state.isMakeCatPresented == true)
}

@MainActor
@Test
func feedOnAppearLoadsFirstPage() async {
    let cat = Cat(
        id: "feed-cat",
        name: "나비",
        place: "집",
        appearanceKey: "abyssinian"
    )
    let viewModel = FeedViewModel(cat: cat, mediaClient: .test)

    viewModel.send(.view(.onAppear))
    await waitUntil { !viewModel.state.isLoading }

    #expect(viewModel.state.items.count == 10)
    #expect(viewModel.state.nextCursor == "feed-page-2")
}

@MainActor
@Test
func feedLoadNextPageAppendsItemsAndStopsAtLastPage() async {
    let recorder = FeedRequestRecorder()
    var mediaClient = MediaClient.test
    mediaClient.fetchFeeds = { catID, cursor in
        await recorder.record(cursor: cursor)
        return try await MediaClient.test.fetchFeeds(catID, cursor)
    }
    let viewModel = FeedViewModel(
        cat: Cat(
            id: "feed-cat",
            name: "나비",
            place: "집",
            appearanceKey: "abyssinian"
        ),
        mediaClient: mediaClient
    )

    viewModel.send(.view(.onAppear))
    await waitUntil { !viewModel.state.isLoading }
    viewModel.send(.view(.loadNextPage))
    await waitUntil { !viewModel.state.isLoading }

    #expect(viewModel.state.items.count == 20)
    #expect(viewModel.state.nextCursor == nil)

    viewModel.send(.view(.loadNextPage))
    await Task.yield()
    #expect(await recorder.cursors.count == 2)
}

@MainActor
@Test
func feedFetchFailureKeepsItemsAndEndsLoading() async {
    let existingItem = Media(
        id: "existing-media",
        thumbnailURL: "https://example.com/existing.jpg",
        mediaType: .photo,
        mediaURL: "https://example.com/existing.jpg"
    )
    var mediaClient = MediaClient.test
    mediaClient.fetchFeeds = { _, _ in
        throw TestError.fetchFeedsFailed
    }
    let viewModel = FeedViewModel(
        cat: Cat(
            id: "feed-cat",
            name: "나비",
            place: "집",
            appearanceKey: "abyssinian"
        ),
        mediaClient: mediaClient
    )
    viewModel.state.items = [existingItem]

    viewModel.send(.view(.onAppear))
    await waitUntil { !viewModel.state.isLoading }

    #expect(viewModel.state.items.map(\.id) == [existingItem.id])
    #expect(viewModel.state.isLoading == false)
}

@MainActor
@Test
func feedPhotoTappedPushesRelayCatRoute() {
    let coordinator = HomeCoordinatorSpy()
    let media = Media(
        id: "photo-media",
        thumbnailURL: "https://example.com/photo.jpg",
        mediaType: .photo,
        mediaURL: "https://example.com/original-photo.jpg"
    )
    let viewModel = FeedViewModel(
        cat: Cat(
            id: "feed-cat",
            name: "나비",
            place: "집",
            appearanceKey: "abyssinian"
        ),
        mediaClient: .test,
        coordinator: coordinator
    )

    viewModel.send(.view(.feedContentTapped(media)))

    guard case let .relayCat(relayCat, catId) = coordinator.routes.first else {
        Issue.record("RelayCat route was not pushed")
        return
    }
    #expect(relayCat.id == media.id)
    #expect(relayCat.memo.isEmpty)
    #expect(relayCat.thumbnailURL == media.thumbnailURL)
    #expect(relayCat.name == "나비")
    #expect(relayCat.mediaType == .photo)
    #expect(relayCat.mediaURL == media.mediaURL)
    #expect(relayCat.isLiked == false)
    #expect(catId == "feed-cat")
}

@MainActor
@Test
func feedVideoTappedUsesMediaURL() {
    let coordinator = HomeCoordinatorSpy()
    let media = Media(
        id: "video-media",
        thumbnailURL: "https://example.com/video-thumbnail.jpg",
        mediaType: .video,
        mediaURL: "https://example.com/video.mp4"
    )
    let viewModel = FeedViewModel(
        cat: Cat(
            id: "feed-cat",
            name: "나비",
            place: "집",
            appearanceKey: "abyssinian"
        ),
        mediaClient: .test,
        coordinator: coordinator
    )

    viewModel.send(.view(.feedContentTapped(media)))

    guard case let .relayCat(relayCat, catId) = coordinator.routes.first else {
        Issue.record("RelayCat route was not pushed")
        return
    }
    #expect(relayCat.mediaType == .video)
    #expect(relayCat.mediaURL == media.mediaURL)
    #expect(catId == "feed-cat")
}

@MainActor
private func waitUntil(_ condition: () -> Bool) async {
    for _ in 0..<100 {
        if condition() { return }
        await Task.yield()
    }
}
