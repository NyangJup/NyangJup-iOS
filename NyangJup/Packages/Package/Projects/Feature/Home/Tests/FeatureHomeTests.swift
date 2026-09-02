//
//  FeatureHomeTests.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import Testing
import SpriteKit
import UIKit

import CoreAdsInterface
import CoreImageLoaderInterface
import DomainCatsInterface
import DomainCatsTesting
import DomainMediaInterface
import DomainMediaTesting
import DomainPixelRewardInterface
import DomainPixelRewardTesting
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

private enum TestError: Error, Sendable {
    case rewardAdFailed
    case fetchCatFeedFailed
    case updateCatProfileFailed
    case deleteCatFailed
    case imageLoadingFailed
    case pixelRewardFailed
}

private actor RewardAdRecorder {
    private(set) var showCount = 0

    func recordShow() {
        showCount += 1
    }
}

private actor RewardAdSequence {
    private var results: [Bool]
    private(set) var showCount = 0

    init(results: [Bool]) {
        self.results = results
    }

    func show() -> Bool {
        showCount += 1
        return results.removeFirst()
    }
}

private actor PixelRewardBalanceGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private(set) var fetchCount = 0

    var isWaiting: Bool {
        continuation != nil
    }

    nonisolated var client: PixelRewardClient {
        PixelRewardClient(
            fetchBalance: {
                await self.wait()
                return PixelRewardBalance(balance: 1)
            },
            createAdSession: { makeAdSession(id: "unused") },
            claimAdReward: { _ in PixelRewardBalance(balance: 1) }
        )
    }

    private func wait() async {
        fetchCount += 1
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }
}

private actor PixelRewardRecorder {
    private var balances: [Result<Int64, TestError>]
    private var sessions: [PixelRewardAdSession]
    private var claims: [Result<Int64, TestError>]
    private var claimErrors: [PixelRewardError]

    private(set) var fetchCount = 0
    private(set) var createCount = 0
    private(set) var claimedSessionIDs: [String] = []

    init(
        balances: [Result<Int64, TestError>],
        sessions: [PixelRewardAdSession] = [],
        claims: [Result<Int64, TestError>] = [],
        claimErrors: [PixelRewardError] = []
    ) {
        self.balances = balances
        self.sessions = sessions
        self.claims = claims
        self.claimErrors = claimErrors
    }

    nonisolated var client: PixelRewardClient {
        PixelRewardClient(
            fetchBalance: { try await self.fetchBalance() },
            createAdSession: { try await self.createAdSession() },
            claimAdReward: { try await self.claimAdReward(sessionId: $0) }
        )
    }

    private func fetchBalance() throws -> PixelRewardBalance {
        fetchCount += 1
        return PixelRewardBalance(balance: try balances.removeFirst().get())
    }

    private func createAdSession() throws -> PixelRewardAdSession {
        createCount += 1
        return sessions.removeFirst()
    }

    private func claimAdReward(sessionId: String) throws -> PixelRewardBalance {
        claimedSessionIDs.append(sessionId)
        if !claimErrors.isEmpty {
            throw claimErrors.removeFirst()
        }
        return PixelRewardBalance(balance: try claims.removeFirst().get())
    }
}

private let testAdsClient = AdsClient(
    setup: {},
    loadRewardAds: {},
    showRewardAds: { true },
    loadNativeAds: { _ in [] }
)

private let successfulImageLoaderClient = ImageLoaderClient { _, _, _, _ in
    UIImage()
}

private let failingImageLoaderClient = ImageLoaderClient { _, _, _, _ in
    throw TestError.imageLoadingFailed
}

private func makeCats(count: Int) -> [Cat] {
    (0..<count).map { index in
        Cat(
            id: "cat-\(index)",
            name: "고양이\(index)",
            place: "집",
            imageURL: "https://example.com/cats/\(index).png"
        )
    }
}

private func makeAdSession(
    id: String,
    expiresAt: Date = .distantFuture
) -> PixelRewardAdSession {
    PixelRewardAdSession(sessionId: id, expiresAt: expiresAt)
}

@MainActor
@Test
func syncingCatsKeepsExistingCatNodeAndAddsMissingCat() async {
    let existingCat = Cat(
        id: "existing-cat",
        name: "나비",
        place: "집",
        imageURL: "https://example.com/cats/existing.png"
    )
    let addedCat = Cat(
        id: "added-cat",
        name: "냥이",
        place: "집",
        imageURL: "https://example.com/cats/added.png"
    )
    let scene = HomeMapScene(
        size: CGSize(width: 390, height: 844),
        cats: [existingCat],
        imageLoaderClient: successfulImageLoaderClient,
        displayScale: 2,
        onCatTapped: { _, _ in },
        onSelectionCleared: {}
    )!
    scene.didMove(to: SKView())
    await waitUntil {
        scene.children.contains {
            $0.userData?["catID"] as? String == existingCat.id
        }
    }

    let existingNode = scene.children.first {
        $0.userData?["catID"] as? String == existingCat.id
    }
    let existingPosition = existingNode?.position

    scene.syncCats([existingCat, addedCat])
    await waitUntil {
        scene.children.contains {
            $0.userData?["catID"] as? String == addedCat.id
        }
    }

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
func syncingCatsUpdatesExistingCatNameTag() async {
    let cat = Cat(
        id: "existing-cat",
        name: "나비",
        place: "집",
        imageURL: "https://example.com/cats/existing.png"
    )
    let updatedCat = Cat(
        id: cat.id,
        name: "후추",
        place: cat.place,
        imageURL: cat.imageURL
    )
    let scene = HomeMapScene(
        size: CGSize(width: 390, height: 844),
        cats: [cat],
        imageLoaderClient: successfulImageLoaderClient,
        displayScale: 2,
        onCatTapped: { _, _ in },
        onSelectionCleared: {}
    )!
    scene.didMove(to: SKView())
    await waitUntil {
        scene.children.contains {
            $0.userData?["catID"] as? String == cat.id
        }
    }

    let existingNode = scene.children.first {
        $0.userData?["catID"] as? String == cat.id
    }

    scene.syncCats([updatedCat])

    let updatedNode = scene.children.first {
        $0.userData?["catID"] as? String == cat.id
    }
    let nameLabel = updatedNode?.childNode(
        withName: "catNameLabel"
    ) as? SKLabelNode

    #expect(updatedNode === existingNode)
    #expect(nameLabel?.text == updatedCat.name)
}

@MainActor
@Test
func syncingCatsRemovesCatMissingFromState() async {
    let removedCat = Cat(
        id: "removed-cat",
        name: "나비",
        place: "집",
        imageURL: "https://example.com/cats/removed.png"
    )
    let remainingCat = Cat(
        id: "remaining-cat",
        name: "냥이",
        place: "집",
        imageURL: "https://example.com/cats/remaining.png"
    )
    let scene = HomeMapScene(
        size: CGSize(width: 390, height: 844),
        cats: [removedCat, remainingCat],
        imageLoaderClient: successfulImageLoaderClient,
        displayScale: 2,
        onCatTapped: { _, _ in },
        onSelectionCleared: {}
    )!
    scene.didMove(to: SKView())
    await waitUntil {
        scene.children.filter {
            $0.userData?["catID"] as? String != nil
        }.count == 2
    }

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
func movingSceneTwiceDoesNotDuplicateCats() async {
    let cat = Cat(
        id: "existing-cat",
        name: "나비",
        place: "집",
        imageURL: "https://example.com/cats/existing.png"
    )
    let scene = HomeMapScene(
        size: CGSize(width: 390, height: 844),
        cats: [cat],
        imageLoaderClient: successfulImageLoaderClient,
        displayScale: 2,
        onCatTapped: { _, _ in },
        onSelectionCleared: {}
    )!

    scene.didMove(to: SKView())
    await waitUntil {
        scene.children.contains {
            $0.userData?["catID"] as? String == cat.id
        }
    }
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
        size: CGSize(width: 47, height: 65),
        cats: [],
        imageLoaderClient: successfulImageLoaderClient,
        displayScale: 2,
        onCatTapped: { _, _ in },
        onSelectionCleared: {}
    )

    #expect(scene == nil)
}

@MainActor
@Test
func catsStartAtRandomPositionsInsideMap() async {
    let scene = HomeMapScene(
        size: CGSize(width: 390, height: 844),
        cats: makeCats(count: 20),
        imageLoaderClient: successfulImageLoaderClient,
        displayScale: 2,
        onCatTapped: { _, _ in },
        onSelectionCleared: {}
    )!

    scene.didMove(to: SKView())
    await waitUntil {
        scene.children.filter {
            $0.userData?["catID"] as? String != nil
        }.count == 20
    }

    let catNodes = scene.children.filter {
        $0.userData?["catID"] as? String != nil
    }
    let positions = Set(catNodes.map(\.position))

    #expect(catNodes.allSatisfy {
        scene.frame.contains($0.calculateAccumulatedFrame())
    })
    #expect(positions.count > 1)
}

@MainActor
@Test
func imageLoadingFailureDoesNotAddCatNode() async {
    let cat = Cat(
        id: "failed-cat",
        name: "나비",
        place: "집",
        imageURL: "https://example.com/cats/failed.png"
    )
    let scene = HomeMapScene(
        size: CGSize(width: 390, height: 844),
        cats: [cat],
        imageLoaderClient: failingImageLoaderClient,
        displayScale: 2,
        onCatTapped: { _, _ in },
        onSelectionCleared: {}
    )!

    scene.didMove(to: SKView())
    for _ in 0..<100 {
        await Task.yield()
    }

    #expect(scene.children.allSatisfy {
        $0.userData?["catID"] as? String == nil
    })
}

@MainActor
@Test
func plusButtonPresentsMakeCatAfterRewardAdCompletes() async {
    let coordinator = HomeCoordinatorSpy()
    let recorder = RewardAdRecorder()
    let pixelRewards = PixelRewardRecorder(
        balances: [.success(0)],
        sessions: [makeAdSession(id: "session-id")],
        claims: [.success(1)]
    )
    let adsClient = AdsClient(
        setup: {},
        loadRewardAds: {},
        showRewardAds: {
            await recorder.recordShow()
            return true
        },
        loadNativeAds: { _ in [] }
    )
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        adsClient: adsClient,
        pixelRewardClient: pixelRewards.client,
        coordinator: coordinator
    )
    viewModel.state.cats = makeCats(count: 4)
    viewModel.state.selectedCatId = "selected-cat"

    #expect(viewModel.state.isMakeCatPresented == false)
    viewModel.send(.view(.plusButtonTapped))
    await waitUntil { viewModel.state.isMakeCatPresented }
    #expect(await recorder.showCount == 1)
    #expect(await pixelRewards.createCount == 1)
    #expect(await pixelRewards.claimedSessionIDs == ["session-id"])
    #expect(viewModel.state.isMakeCatPresented == true)
    #expect(viewModel.state.selectedCatId == nil)
}

@MainActor
@Test
func failedRewardAdKeepsMakeCatDismissed() async {
    let recorder = RewardAdRecorder()
    let pixelRewards = PixelRewardRecorder(
        balances: [.success(0)],
        sessions: [makeAdSession(id: "session-id")]
    )
    let adsClient = AdsClient(
        setup: {},
        loadRewardAds: {},
        showRewardAds: {
            await recorder.recordShow()
            throw TestError.rewardAdFailed
        },
        loadNativeAds: { _ in [] }
    )
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        adsClient: adsClient,
        pixelRewardClient: pixelRewards.client,
        coordinator: HomeCoordinatorSpy()
    )
    viewModel.state.cats = makeCats(count: 1)

    viewModel.send(.view(.plusButtonTapped))
    await waitForRewardAdShows(recorder, count: 1)

    #expect(await recorder.showCount == 1)
    #expect(!viewModel.state.isMakeCatPresented)
    #expect(viewModel.state.pendingAdSession?.sessionId == "session-id")
}

@MainActor
@Test
func notReadyRewardAdKeepsMakeCatDismissed() async {
    let recorder = RewardAdRecorder()
    let pixelRewards = PixelRewardRecorder(
        balances: [.success(0)],
        sessions: [makeAdSession(id: "session-id")]
    )
    let adsClient = AdsClient(
        setup: {},
        loadRewardAds: {},
        showRewardAds: {
            await recorder.recordShow()
            throw AdsError.adNotReady
        },
        loadNativeAds: { _ in [] }
    )
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        adsClient: adsClient,
        pixelRewardClient: pixelRewards.client,
        coordinator: HomeCoordinatorSpy()
    )
    viewModel.state.cats = makeCats(count: 1)

    viewModel.send(.view(.plusButtonTapped))
    await waitForRewardAdShows(recorder, count: 1)

    #expect(await recorder.showCount == 1)
    #expect(!viewModel.state.isMakeCatPresented)
    #expect(viewModel.state.pendingAdSession?.sessionId == "session-id")
}

@MainActor
@Test
func homeOnAppearFetchesPixelRewardBalance() async {
    let pixelRewards = PixelRewardRecorder(balances: [.success(3)])
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        adsClient: testAdsClient,
        pixelRewardClient: pixelRewards.client,
        coordinator: HomeCoordinatorSpy()
    )

    viewModel.send(.view(.onAppear))
    await waitUntil { viewModel.state.pixelRewardBalance == 3 }

    #expect(viewModel.state.pixelRewardBalance == 3)
    #expect(await pixelRewards.fetchCount == 1)
}

@MainActor
@Test
func availableBalancePresentsMakeCatWithoutRewardAd() async {
    let adRecorder = RewardAdRecorder()
    let pixelRewards = PixelRewardRecorder(balances: [.success(1)])
    let adsClient = AdsClient(
        setup: {},
        loadRewardAds: {},
        showRewardAds: {
            await adRecorder.recordShow()
            return true
        },
        loadNativeAds: { _ in [] }
    )
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        adsClient: adsClient,
        pixelRewardClient: pixelRewards.client,
        coordinator: HomeCoordinatorSpy()
    )

    viewModel.send(.view(.plusButtonTapped))
    await waitUntil { viewModel.state.isMakeCatPresented }

    #expect(await adRecorder.showCount == 0)
    #expect(await pixelRewards.createCount == 0)
    #expect(await pixelRewards.claimedSessionIDs.isEmpty)
}

@MainActor
@Test
func dismissedRewardAdReusesSessionOnNextAttempt() async {
    let ads = RewardAdSequence(results: [false, true])
    let pixelRewards = PixelRewardRecorder(
        balances: [.success(0), .success(0)],
        sessions: [makeAdSession(id: "reused-session")],
        claims: [.success(1)]
    )
    let adsClient = AdsClient(
        setup: {},
        loadRewardAds: {},
        showRewardAds: { await ads.show() },
        loadNativeAds: { _ in [] }
    )
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        adsClient: adsClient,
        pixelRewardClient: pixelRewards.client,
        coordinator: HomeCoordinatorSpy()
    )

    viewModel.send(.view(.plusButtonTapped))
    await waitUntil { !viewModel.state.isRewardFlowInProgress }
    #expect(viewModel.state.pendingAdSession?.sessionId == "reused-session")

    viewModel.send(.view(.plusButtonTapped))
    await waitUntil { viewModel.state.isMakeCatPresented }

    #expect(await ads.showCount == 2)
    #expect(await pixelRewards.createCount == 1)
    #expect(await pixelRewards.claimedSessionIDs == ["reused-session"])
}

@MainActor
@Test
func failedClaimRetriesWithoutShowingRewardAdAgain() async {
    let adRecorder = RewardAdRecorder()
    let pixelRewards = PixelRewardRecorder(
        balances: [.success(0), .success(0)],
        sessions: [makeAdSession(id: "claim-session")],
        claims: [.failure(.pixelRewardFailed), .success(1)]
    )
    let adsClient = AdsClient(
        setup: {},
        loadRewardAds: {},
        showRewardAds: {
            await adRecorder.recordShow()
            return true
        },
        loadNativeAds: { _ in [] }
    )
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        adsClient: adsClient,
        pixelRewardClient: pixelRewards.client,
        coordinator: HomeCoordinatorSpy()
    )

    viewModel.send(.view(.plusButtonTapped))
    await waitUntil {
        !viewModel.state.isRewardFlowInProgress &&
        viewModel.state.hasEarnedPendingAdReward
    }
    viewModel.send(.view(.plusButtonTapped))
    await waitUntil { viewModel.state.isMakeCatPresented }

    #expect(await adRecorder.showCount == 1)
    #expect(await pixelRewards.createCount == 1)
    #expect(await pixelRewards.claimedSessionIDs == ["claim-session", "claim-session"])
}

@MainActor
@Test
func sessionNotFoundClaimCreatesNewSessionOnNextAttempt() async {
    let adRecorder = RewardAdRecorder()
    let pixelRewards = PixelRewardRecorder(
        balances: [.success(0), .success(0)],
        sessions: [
            makeAdSession(id: "missing-session"),
            makeAdSession(id: "new-session")
        ],
        claims: [.success(1)],
        claimErrors: [.sessionNotFound]
    )
    let adsClient = AdsClient(
        setup: {},
        loadRewardAds: {},
        showRewardAds: {
            await adRecorder.recordShow()
            return true
        },
        loadNativeAds: { _ in [] }
    )
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        adsClient: adsClient,
        pixelRewardClient: pixelRewards.client,
        coordinator: HomeCoordinatorSpy()
    )

    viewModel.send(.view(.plusButtonTapped))
    await waitUntil { !viewModel.state.isRewardFlowInProgress }

    #expect(viewModel.state.pendingAdSession == nil)
    #expect(!viewModel.state.hasEarnedPendingAdReward)

    viewModel.send(.view(.plusButtonTapped))
    await waitUntil { viewModel.state.isMakeCatPresented }

    #expect(await adRecorder.showCount == 2)
    #expect(await pixelRewards.createCount == 2)
    #expect(await pixelRewards.claimedSessionIDs == ["missing-session", "new-session"])
}

@MainActor
@Test
func expiredPendingSessionCreatesNewSession() async {
    let pixelRewards = PixelRewardRecorder(
        balances: [.success(0)],
        sessions: [makeAdSession(id: "new-session")]
    )
    let adsClient = AdsClient(
        setup: {},
        loadRewardAds: {},
        showRewardAds: { false },
        loadNativeAds: { _ in [] }
    )
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        adsClient: adsClient,
        pixelRewardClient: pixelRewards.client,
        coordinator: HomeCoordinatorSpy()
    )
    viewModel.state.pendingAdSession = makeAdSession(
        id: "expired-session",
        expiresAt: .distantPast
    )
    viewModel.state.hasEarnedPendingAdReward = true

    viewModel.send(.view(.plusButtonTapped))
    await waitUntil { !viewModel.state.isRewardFlowInProgress }

    #expect(await pixelRewards.createCount == 1)
    #expect(viewModel.state.pendingAdSession?.sessionId == "new-session")
    #expect(!viewModel.state.hasEarnedPendingAdReward)
}

@MainActor
@Test
func successfulBalanceReconcilesAmbiguousClaimFailure() async {
    let adRecorder = RewardAdRecorder()
    let pixelRewards = PixelRewardRecorder(
        balances: [.success(0), .success(1)],
        sessions: [makeAdSession(id: "ambiguous-session")],
        claims: [.failure(.pixelRewardFailed)]
    )
    let adsClient = AdsClient(
        setup: {},
        loadRewardAds: {},
        showRewardAds: {
            await adRecorder.recordShow()
            return true
        },
        loadNativeAds: { _ in [] }
    )
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        adsClient: adsClient,
        pixelRewardClient: pixelRewards.client,
        coordinator: HomeCoordinatorSpy()
    )

    viewModel.send(.view(.plusButtonTapped))
    await waitUntil {
        !viewModel.state.isRewardFlowInProgress &&
        viewModel.state.hasEarnedPendingAdReward
    }
    viewModel.send(.view(.plusButtonTapped))
    await waitUntil { viewModel.state.isMakeCatPresented }

    #expect(await adRecorder.showCount == 1)
    #expect(await pixelRewards.claimedSessionIDs == ["ambiguous-session"])
    #expect(viewModel.state.pendingAdSession == nil)
}

@MainActor
@Test
func repeatedPlusTapStartsOnlyOneRewardFlow() async {
    let gate = PixelRewardBalanceGate()
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        adsClient: testAdsClient,
        pixelRewardClient: gate.client,
        coordinator: HomeCoordinatorSpy()
    )

    viewModel.send(.view(.plusButtonTapped))
    viewModel.send(.view(.plusButtonTapped))
    await waitUntilAsync { await gate.isWaiting }

    #expect(await gate.fetchCount == 1)
    await gate.resume()
    await waitUntil { viewModel.state.isMakeCatPresented }
}

@MainActor
@Test
func registrationCompletionAndCloseRefreshBalance() async {
    let pixelRewards = PixelRewardRecorder(
        balances: [.success(2), .success(1)]
    )
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        adsClient: testAdsClient,
        pixelRewardClient: pixelRewards.client,
        coordinator: HomeCoordinatorSpy()
    )
    let cat = makeCats(count: 1)[0]

    viewModel.send(.internal(.catRegistered(cat)))
    await waitUntil { viewModel.state.pixelRewardBalance == 2 }
    viewModel.send(.internal(.catRegistrationClosed))
    await waitUntil { viewModel.state.pixelRewardBalance == 1 }

    #expect(await pixelRewards.fetchCount == 2)
}

@MainActor
@Test
func plusButtonAtCatLimitPresentsAlert() {
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        adsClient: testAdsClient,
        pixelRewardClient: .test,
        coordinator: HomeCoordinatorSpy()
    )
    viewModel.state.cats = makeCats(count: HomeViewModel.maximumCatCount)
    viewModel.state.selectedCatId = viewModel.state.cats.first?.id
    let selectedCatId = viewModel.state.selectedCatId

    viewModel.send(.view(.plusButtonTapped))

    #expect(viewModel.state.isMakeCatPresented == false)
    #expect(viewModel.state.showsCatLimitAlert == true)
    #expect(viewModel.state.selectedCatId == selectedCatId)
}

@MainActor
@Test
func catTappedSelectsCat() {
    let selectedCat = Cat(
        id: "selected-cat",
        name: "나비",
        place: "집",
        imageURL: "https://example.com/cats/cat-1.png"
    )
    let coordinator = HomeCoordinatorSpy()
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        adsClient: testAdsClient,
        pixelRewardClient: .test,
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
        adsClient: testAdsClient,
        pixelRewardClient: .test,
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
        adsClient: testAdsClient,
        pixelRewardClient: .test,
        coordinator: coordinator
    )
    viewModel.state.selectedCatId = "selected-cat"

    viewModel.send(.view(.speechBubbleTapped))

    #expect(coordinator.routes == [.feed(catId: "selected-cat")])
}

@MainActor
@Test
func catRegistrationDelegateActionsUpdatePresentationAndCats() {
    let registeredCat = Cat(
        id: "registered-cat",
        name: "나비",
        place: "집",
        imageURL: "https://example.com/cats/registered.png"
    )
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        adsClient: testAdsClient,
        pixelRewardClient: .test,
        coordinator: HomeCoordinatorSpy()
    )
    viewModel.state.isMakeCatPresented = true

    viewModel.send(.internal(.catRegistered(registeredCat)))

    #expect(viewModel.state.cats == [registeredCat])
    #expect(!viewModel.state.isMakeCatPresented)

    viewModel.state.isMakeCatPresented = true
    viewModel.send(.internal(.catRegistrationClosed))

    #expect(!viewModel.state.isMakeCatPresented)
    #expect(viewModel.state.cats == [registeredCat])
}

@MainActor
@Test
func lateFetchKeepsCatCreatedWhileRequestWasInFlight() async {
    let localCat = Cat(
        id: "local-cat",
        name: "나비",
        place: "집",
        imageURL: "https://example.com/cats/cat-1.png"
    )
    let fetchedCat = Cat(
        id: "fetched-cat",
        name: "냥이",
        place: "집",
        imageURL: "https://example.com/cats/cat-1.png"
    )
    let gate = FetchCatsGate()
    var catsClient = CatsClient.test
    catsClient.fetchCats = {
        await gate.wait()
        return [
            Cat(
                id: "fetched-cat",
                name: "냥이",
                place: "집",
                imageURL: "https://example.com/cats/cat-1.png"
            )
        ]
    }
    let viewModel = HomeViewModel(
        catsClient: catsClient,
        profileClient: .test,
        adsClient: testAdsClient,
        pixelRewardClient: .test,
        coordinator: HomeCoordinatorSpy()
    )

    viewModel.send(.view(.onAppear))
    for _ in 0..<100 {
        if await gate.isWaiting { break }
        await Task.yield()
    }
    viewModel.send(.internal(.catRegistered(localCat)))

    await gate.resume()
    await waitUntil { viewModel.state.cats.count == 2 }

    #expect(viewModel.state.cats.map(\.id) == [fetchedCat.id, localCat.id])
}

@MainActor
@Test
func homeUpdatesAndDeletesCatsLocally() {
    let originalCat = Cat(
        id: "updated-cat",
        name: "수정 전",
        place: "이전 장소",
        imageURL: "https://example.com/cats/cat-1.png"
    )
    let updatedCat = Cat(
        id: originalCat.id,
        name: "수정 후",
        place: "새 장소",
        imageURL: originalCat.imageURL
    )
    let deletedCat = Cat(
        id: "deleted-cat",
        name: "삭제할 고양이",
        place: "집",
        imageURL: "https://example.com/cats/cat-2.png"
    )
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test,
        adsClient: testAdsClient,
        pixelRewardClient: .test,
        coordinator: HomeCoordinatorSpy()
    )
    viewModel.state.cats = [originalCat, deletedCat]
    viewModel.state.selectedCatId = deletedCat.id

    viewModel.send(.internal(.catUpdated(updatedCat)))
    viewModel.send(.internal(.catDeleted(id: deletedCat.id)))

    #expect(viewModel.state.cats.map(\.id) == [updatedCat.id])
    #expect(viewModel.state.cats.first?.name == updatedCat.name)
    #expect(viewModel.state.cats.first?.place == updatedCat.place)
    #expect(viewModel.state.selectedCatId == nil)
}

@MainActor
@Test
func feedOnAppearLoadsFirstPage() async {
    let cat = Cat(
        id: "feed-cat",
        name: "나비",
        place: "집",
        imageURL: "https://example.com/cats/cat-1.png"
    )
    let viewModel = FeedViewModel(
        cat: cat,
        catsClient: .test,
        onCatDeleted: { _ in },
        onCatUpdated: { _ in }
    )

    viewModel.send(.view(.onAppear))
    await waitUntil { !viewModel.state.isLoading }

    #expect(viewModel.state.items.count == 9)
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
            imageURL: "https://example.com/cats/cat-1.png"
        ),
        catsClient: .test,
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
            imageURL: "https://example.com/cats/cat-1.png"
        ),
        catsClient: .test,
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
    var catsClient = CatsClient.test
    catsClient.fetchCatFeed = { catID, cursor in
        await recorder.record(cursor: cursor)
        return try await CatsClient.test.fetchCatFeed(catID, cursor)
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
            imageURL: "https://example.com/cats/cat-1.png"
        ),
        catsClient: catsClient,
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
    let cat = Cat(
        id: "feed-cat",
        name: "나비",
        place: "집",
        imageURL: "https://example.com/cats/cat-1.png"
    )
    let firstItem = Media(
        id: "first-page-media",
        catId: cat.id,
        userId: "user-1",
        comment: "",
        thumbnailURL: "https://example.com/first.jpg",
        mediaType: .photo,
        mediaURL: "https://example.com/first.jpg"
    )
    let secondItem = Media(
        id: "second-page-media",
        catId: cat.id,
        userId: "user-1",
        comment: "",
        thumbnailURL: "https://example.com/second.jpg",
        mediaType: .video,
        mediaURL: "https://example.com/second.mp4"
    )
    var catsClient = CatsClient.test
    catsClient.fetchCatFeed = { _, cursor in
        await recorder.record(cursor: cursor)
        return CatFeed(
            cat: cat,
            items: cursor == nil ? [firstItem] : [secondItem],
            nextCursor: cursor == nil ? "feed-page-2" : nil
        )
    }
    let viewModel = FeedViewModel(
        cat: cat,
        catsClient: catsClient,
        onCatDeleted: { _ in },
        onCatUpdated: { _ in }
    )

    viewModel.send(.view(.onAppear))
    await waitUntil { !viewModel.state.isLoading }
    viewModel.send(.view(.loadNextPage))
    await waitUntil { !viewModel.state.isLoading }

    #expect(viewModel.state.items.map(\.id) == [firstItem.id, secondItem.id])
    #expect(viewModel.state.nextCursor == nil)

    viewModel.send(.view(.loadNextPage))
    await Task.yield()
    #expect(await recorder.cursors == [nil, "feed-page-2"])
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
    var catsClient = CatsClient.test
    catsClient.fetchCatFeed = { _, _ in
        throw TestError.fetchCatFeedFailed
    }
    let viewModel = FeedViewModel(
        cat: Cat(
            id: "feed-cat",
            name: "나비",
            place: "집",
            imageURL: "https://example.com/cats/cat-1.png"
        ),
        catsClient: catsClient,
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
            imageURL: "https://example.com/cats/cat-1.png"
        ),
        catsClient: .test,
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
            imageURL: "https://example.com/cats/cat-1.png"
        ),
        catsClient: .test,
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
        imageURL: "https://example.com/cats/cat-1.png"
    )
    let updatedCat = Cat(
        id: originalCat.id,
        name: "수정 후",
        place: "새 장소",
        imageURL: originalCat.imageURL
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
        imageURL: "https://example.com/cats/cat-1.png"
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
        imageURL: "https://example.com/cats/cat-1.png"
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
        imageURL: "https://example.com/cats/cat-1.png"
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

private func waitForRewardAdShows(
    _ recorder: RewardAdRecorder,
    count: Int
) async {
    for _ in 0..<1_000 {
        if await recorder.showCount == count { return }
        try? await Task.sleep(for: .milliseconds(1))
    }
}
