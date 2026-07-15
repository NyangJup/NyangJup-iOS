//
//  FeatureHomeTests.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import Testing

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

private enum TestError: Error {
    case createCatFailed
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

    #expect(viewModel.state.isMakeCatPresented == false)
    viewModel.send(.view(.plusButtonTapped))
    #expect(viewModel.state.isMakeCatPresented == true)
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
