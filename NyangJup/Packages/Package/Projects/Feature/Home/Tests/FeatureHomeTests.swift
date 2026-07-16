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

private enum TestError: Error {
    case createCatFailed
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
private func waitUntil(_ condition: () -> Bool) async {
    for _ in 0..<100 {
        if condition() { return }
        await Task.yield()
    }
}
