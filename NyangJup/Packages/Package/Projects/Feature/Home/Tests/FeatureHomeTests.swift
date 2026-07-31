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

private actor CatProfileRequestRecorder {
    private(set) var catID: String?
    private(set) var request: UpdateCatProfileRequestDTO?

    func record(catID: String, request: UpdateCatProfileRequestDTO) {
        self.catID = catID
        self.request = request
    }
}

private actor DeleteCatRequestRecorder {
    private(set) var catID: String?

    func record(catID: String) {
        self.catID = catID
    }
}

@MainActor
private final class CatOutputSpy {
    private(set) var deletedCatIDs: [String] = []
    private(set) var updatedCats: [Cat] = []

    func catDeleted(id: String) {
        deletedCatIDs.append(id)
    }

    func catUpdated(_ cat: Cat) {
        updatedCats.append(cat)
    }
}

private enum TestError: Error {
    case createCatFailed
    case fetchFeedsFailed
    case updateCatProfileFailed
    case deleteCatFailed
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
func homeKeepsUpdatedCatAndDeletedCatRemovedAfterRefresh() async {
    let originalCat = Cat(
        id: "updated-cat",
        name: "수정 전",
        place: "이전 장소",
        appearanceKey: "abyssinian"
    )
    let updatedCat = Cat(
        id: originalCat.id,
        name: "수정 후",
        place: "새 장소",
        appearanceKey: originalCat.appearanceKey
    )
    let deletedCat = Cat(
        id: "deleted-cat",
        name: "삭제할 고양이",
        place: "집",
        appearanceKey: "americanShorthair"
    )
    let newlyFetchedCat = Cat(
        id: "newly-fetched-cat",
        name: "새 고양이",
        place: "공원",
        appearanceKey: "bengal"
    )
    var catsClient = CatsClient.test
    catsClient.fetchCats = { _ in [originalCat, deletedCat, newlyFetchedCat] }
    let viewModel = HomeViewModel(
        catsClient: catsClient,
        profileClient: .test,
        coordinator: HomeCoordinatorSpy()
    )
    viewModel.state.cats = [originalCat, deletedCat]
    viewModel.state.selectedCatId = deletedCat.id

    viewModel.send(.internal(.catUpdated(updatedCat)))
    viewModel.send(.internal(.catDeleted(id: deletedCat.id)))

    #expect(viewModel.state.cats.map(\.id) == [updatedCat.id])
    #expect(viewModel.state.cats.first?.name == updatedCat.name)
    #expect(viewModel.state.selectedCatId == nil)
    #expect(viewModel.state.updatedCatsById[updatedCat.id]?.place == updatedCat.place)
    #expect(viewModel.state.deletedCatIds.contains(deletedCat.id))

    viewModel.send(.view(.onAppear))
    await waitUntil {
        viewModel.state.cats.first?.name == updatedCat.name
            && viewModel.state.cats.count == 2
    }

    #expect(viewModel.state.cats.map(\.id) == [updatedCat.id, newlyFetchedCat.id])
    #expect(viewModel.state.cats.first?.name == updatedCat.name)
    #expect(viewModel.state.cats.first?.place == updatedCat.place)
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
    let viewModel = FeedViewModel(
        cat: cat,
        catsClient: .test,
        mediaClient: .test,
        onCatDeleted: { _ in },
        onCatUpdated: { _ in }
    )

    viewModel.send(.view(.onAppear))
    await waitUntil { !viewModel.state.isLoading }

    #expect(viewModel.state.items.count == 10)
    #expect(viewModel.state.nextCursor == "feed-page-2")
}

@MainActor
@Test
func feedPlusButtonPresentsAndDismissesCamera() {
    let viewModel = FeedViewModel(
        cat: Cat(
            id: "feed-cat",
            name: "나비",
            place: "집",
            appearanceKey: "abyssinian"
        ),
        catsClient: .test,
        mediaClient: .test,
        onCatDeleted: { _ in },
        onCatUpdated: { _ in }
    )

    viewModel.send(.view(.plusButtonTapped))
    #expect(viewModel.state.isCameraPresented)

    viewModel.send(.view(.cameraDismissed))
    #expect(viewModel.state.isCameraPresented == false)
}

@MainActor
@Test
func feedCameraCompletionPrependsItemAndKeepsExistingPagination() {
    let addedItem = Media(
        id: "added-media",
        catId: "feed-cat",
        userId: "test-user-id",
        comment: "추가된 콘텐츠",
        thumbnailURL: "https://example.com/added-thumbnail.jpg",
        mediaType: .video,
        mediaURL: "https://example.com/added-video.mp4"
    )
    let existingItems = [
        Media(
            id: "existing-media-1",
            catId: "feed-cat",
            userId: "test-user-id",
            comment: "",
            thumbnailURL: "https://example.com/existing-1.jpg",
            mediaType: .photo,
            mediaURL: "https://example.com/existing-1.jpg"
        ),
        Media(
            id: "existing-media-2",
            catId: "feed-cat",
            userId: "test-user-id",
            comment: "",
            thumbnailURL: "https://example.com/existing-2.jpg",
            mediaType: .photo,
            mediaURL: "https://example.com/existing-2.jpg"
        )
    ]
    let viewModel = FeedViewModel(
        cat: Cat(
            id: "feed-cat",
            name: "나비",
            place: "집",
            appearanceKey: "abyssinian"
        ),
        catsClient: .test,
        mediaClient: .test,
        onCatDeleted: { _ in },
        onCatUpdated: { _ in }
    )
    viewModel.state.items = existingItems
    viewModel.state.nextCursor = "existing-cursor"
    viewModel.state.isCameraPresented = true

    viewModel.send(.view(.cameraCompleted(addedItem)))

    #expect(viewModel.state.items.map(\.id) == [
        addedItem.id,
        existingItems[0].id,
        existingItems[1].id
    ])
    #expect(viewModel.state.nextCursor == "existing-cursor")
    #expect(viewModel.state.isCameraPresented == false)
}

@MainActor
@Test
func feedOnAppearDoesNotReloadExistingItems() async {
    let recorder = FeedRequestRecorder()
    var mediaClient = MediaClient.test
    mediaClient.fetchFeeds = { _, cursor in
        await recorder.record(cursor: cursor)
        return try await MediaClient.test.fetchFeeds("feed-cat", cursor)
    }
    let existingItem = Media(
        id: "existing-media",
        catId: "feed-cat",
        userId: "test-user-id",
        comment: "",
        thumbnailURL: "https://example.com/existing.jpg",
        mediaType: .photo,
        mediaURL: "https://example.com/existing.jpg"
    )
    let viewModel = FeedViewModel(
        cat: Cat(
            id: "feed-cat",
            name: "나비",
            place: "집",
            appearanceKey: "abyssinian"
        ),
        catsClient: .test,
        mediaClient: mediaClient,
        onCatDeleted: { _ in },
        onCatUpdated: { _ in }
    )
    viewModel.state.items = [existingItem]
    viewModel.state.nextCursor = "preserved-cursor"

    viewModel.send(.view(.onAppear))
    await Task.yield()

    #expect(await recorder.cursors.isEmpty)
    #expect(viewModel.state.items.map(\.id) == [existingItem.id])
    #expect(viewModel.state.nextCursor == "preserved-cursor")
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
        catsClient: .test,
        mediaClient: mediaClient,
        onCatDeleted: { _ in },
        onCatUpdated: { _ in }
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
        catId: "feed-cat",
        userId: "test-user-id",
        comment: "",
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
        catsClient: .test,
        mediaClient: mediaClient,
        onCatDeleted: { _ in },
        onCatUpdated: { _ in }
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
        catId: "feed-cat",
        userId: "test-user-id",
        comment: "사진 코멘트",
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
        catsClient: .test,
        mediaClient: .test,
        onCatDeleted: { _ in },
        onCatUpdated: { _ in },
        coordinator: coordinator
    )

    viewModel.send(.view(.feedContentTapped(media)))

    guard case let .relayCat(relayCat) = coordinator.routes.first else {
        Issue.record("RelayCat route was not pushed")
        return
    }
    #expect(relayCat.mediaId == media.id)
    #expect(relayCat.comment == media.comment)
    #expect(relayCat.thumbnailURL == media.thumbnailURL)
    #expect(relayCat.name == "나비")
    #expect(relayCat.mediaType == .photo)
    #expect(relayCat.mediaURL == media.mediaURL)
    #expect(relayCat.isLiked == false)
    #expect(relayCat.catId == "feed-cat")
}

@MainActor
@Test
func feedVideoTappedUsesMediaURL() {
    let coordinator = HomeCoordinatorSpy()
    let media = Media(
        id: "video-media",
        catId: "feed-cat",
        userId: "test-user-id",
        comment: "영상 코멘트",
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
        catsClient: .test,
        mediaClient: .test,
        onCatDeleted: { _ in },
        onCatUpdated: { _ in },
        coordinator: coordinator
    )

    viewModel.send(.view(.feedContentTapped(media)))

    guard case let .relayCat(relayCat) = coordinator.routes.first else {
        Issue.record("RelayCat route was not pushed")
        return
    }
    #expect(relayCat.mediaType == .video)
    #expect(relayCat.mediaURL == media.mediaURL)
    #expect(relayCat.catId == "feed-cat")
}

@MainActor
@Test
func feedUpdateProfileSuccessUpdatesStateAndSendsOutput() async {
    let originalCat = Cat(
        id: "feed-cat",
        name: "수정 전",
        place: "이전 장소",
        appearanceKey: "abyssinian"
    )
    let updatedCat = Cat(
        id: originalCat.id,
        name: "수정 후",
        place: "새 장소",
        appearanceKey: originalCat.appearanceKey
    )
    let requestRecorder = CatProfileRequestRecorder()
    let outputSpy = CatOutputSpy()
    var catsClient = CatsClient.test
    catsClient.updateCatProfile = { catID, request in
        await requestRecorder.record(catID: catID, request: request)
        return updatedCat
    }
    let viewModel = FeedViewModel(
        cat: originalCat,
        catsClient: catsClient,
        mediaClient: .test,
        onCatDeleted: outputSpy.catDeleted,
        onCatUpdated: outputSpy.catUpdated
    )
    viewModel.state.editName = "  수정 후  "
    viewModel.state.editPlace = "  새 장소  "

    viewModel.send(.view(.updateProfileAlertTapped))
    await waitUntil { outputSpy.updatedCats.count == 1 }

    #expect(await requestRecorder.catID == originalCat.id)
    #expect(await requestRecorder.request?.name == updatedCat.name)
    #expect(await requestRecorder.request?.place == updatedCat.place)
    #expect(viewModel.state.cat.id == updatedCat.id)
    #expect(viewModel.state.cat.name == updatedCat.name)
    #expect(viewModel.state.cat.place == updatedCat.place)
    #expect(outputSpy.updatedCats.map(\.id) == [updatedCat.id])
}

@MainActor
@Test
func feedUpdateProfileFailureKeepsStateAndDoesNotSendOutput() async {
    let originalCat = Cat(
        id: "feed-cat",
        name: "수정 전",
        place: "이전 장소",
        appearanceKey: "abyssinian"
    )
    let requestRecorder = CatProfileRequestRecorder()
    let outputSpy = CatOutputSpy()
    var catsClient = CatsClient.test
    catsClient.updateCatProfile = { catID, request in
        await requestRecorder.record(catID: catID, request: request)
        throw TestError.updateCatProfileFailed
    }
    let viewModel = FeedViewModel(
        cat: originalCat,
        catsClient: catsClient,
        mediaClient: .test,
        onCatDeleted: outputSpy.catDeleted,
        onCatUpdated: outputSpy.catUpdated
    )
    viewModel.state.editName = "수정 후"
    viewModel.state.editPlace = "새 장소"

    viewModel.send(.view(.updateProfileAlertTapped))
    await waitUntilAsync { await requestRecorder.catID != nil }
    await Task.yield()

    #expect(viewModel.state.cat.id == originalCat.id)
    #expect(viewModel.state.cat.name == originalCat.name)
    #expect(viewModel.state.cat.place == originalCat.place)
    #expect(outputSpy.updatedCats.isEmpty)
}

@MainActor
@Test
func feedDeleteSuccessSendsOutputAndPopsCoordinator() async {
    let cat = Cat(
        id: "feed-cat",
        name: "나비",
        place: "집",
        appearanceKey: "abyssinian"
    )
    let requestRecorder = DeleteCatRequestRecorder()
    let outputSpy = CatOutputSpy()
    let coordinator = HomeCoordinatorSpy()
    coordinator.push(to: .feed(catId: cat.id))
    var catsClient = CatsClient.test
    catsClient.deleteCat = { catID in
        await requestRecorder.record(catID: catID)
    }
    let viewModel = FeedViewModel(
        cat: cat,
        catsClient: catsClient,
        mediaClient: .test,
        onCatDeleted: outputSpy.catDeleted,
        onCatUpdated: outputSpy.catUpdated,
        coordinator: coordinator
    )

    viewModel.send(.view(.deleteAlertTapped))
    await waitUntil { outputSpy.deletedCatIDs.count == 1 }

    #expect(await requestRecorder.catID == cat.id)
    #expect(outputSpy.deletedCatIDs == [cat.id])
    #expect(coordinator.routes.isEmpty)
}

@MainActor
@Test
func feedDeleteFailureDoesNotSendOutputOrPopCoordinator() async {
    let cat = Cat(
        id: "feed-cat",
        name: "나비",
        place: "집",
        appearanceKey: "abyssinian"
    )
    let requestRecorder = DeleteCatRequestRecorder()
    let outputSpy = CatOutputSpy()
    let coordinator = HomeCoordinatorSpy()
    coordinator.push(to: .feed(catId: cat.id))
    var catsClient = CatsClient.test
    catsClient.deleteCat = { catID in
        await requestRecorder.record(catID: catID)
        throw TestError.deleteCatFailed
    }
    let viewModel = FeedViewModel(
        cat: cat,
        catsClient: catsClient,
        mediaClient: .test,
        onCatDeleted: outputSpy.catDeleted,
        onCatUpdated: outputSpy.catUpdated,
        coordinator: coordinator
    )

    viewModel.send(.view(.deleteAlertTapped))
    await waitUntilAsync { await requestRecorder.catID != nil }
    await Task.yield()

    #expect(outputSpy.deletedCatIDs.isEmpty)
    #expect(coordinator.routes == [.feed(catId: cat.id)])
}

@MainActor
private func waitUntil(_ condition: () -> Bool) async {
    for _ in 0..<100 {
        if condition() { return }
        await Task.yield()
    }
}

@MainActor
private func waitUntilAsync(_ condition: @MainActor () async -> Bool) async {
    for _ in 0..<100 {
        if await condition() { return }
        await Task.yield()
    }
}
