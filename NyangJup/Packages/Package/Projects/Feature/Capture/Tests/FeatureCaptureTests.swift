//
//  FeatureCaptureTests.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import Foundation
import Testing
@testable import FeatureCapture
import CoreCameraInterface
import CoreCameraTesting
import FeatureCaptureInterface
import FeatureCommonInterface

@MainActor
private final class CaptureCoordinatorSpy: Coordinator {
    typealias Route = CaptureRoute

    var routes: [CaptureRoute] = []

    func push(to route: CaptureRoute) {
        routes.append(route)
    }

    func pop() {
        _ = routes.popLast()
    }
}

@MainActor
@Test
func clampsZoomFactor() {
    #expect(CaptureViewModel.clampedZoomFactor(0.5) == 1)
    #expect(CaptureViewModel.clampedZoomFactor(2) == 2)
    #expect(CaptureViewModel.clampedZoomFactor(4) == 3)
}

@MainActor
@Test
func captureViewModelUpdatesCaptureState() {
    let coordinator = CaptureCoordinatorSpy()
    let viewModel = CaptureViewModel(
        cameraClient: .test,
        videoTrimClient: VideoTrimClient(),
        coordinator: coordinator,
        configuration: .init(showsModePicker: false)
    )

    #expect(viewModel.state.mode == .photo)
    #expect(viewModel.state.showsModePicker == false)

    viewModel.send(.view(.modeChanged(.video)))
    #expect(viewModel.state.mode == .video)

    viewModel.send(.internal(.captureCompleted(CapturedMedia(data: Data([0, 1, 2]), mode: .photo))))
    #expect(viewModel.state.hasResultMedia)

    viewModel.send(.view(.retakeButtonTapped))
    #expect(viewModel.state.hasResultMedia == false)
    #expect(viewModel.state.isRecording == nil)
}

@MainActor
@Test
func usingPhotoPushesGenerateRoute() {
    let coordinator = CaptureCoordinatorSpy()
    let viewModel = CaptureViewModel(
        cameraClient: .test,
        videoTrimClient: VideoTrimClient(),
        coordinator: coordinator,
        configuration: .init()
    )

    viewModel.send(.internal(.captureCompleted(CapturedMedia(data: Data([0, 1, 2]), mode: .photo))))
    viewModel.send(.view(.useButtonTapped))

    #expect(coordinator.routes == [.upload])
}

@MainActor
@Test
func exportedVideoReplacesCapturedMediaAndPushesGenerateRoute() {
    let coordinator = CaptureCoordinatorSpy()
    let viewModel = CaptureViewModel(
        cameraClient: .test,
        videoTrimClient: VideoTrimClient(),
        coordinator: coordinator,
        configuration: .init()
    )
    let exportedMedia = CapturedMedia(
        url: URL(fileURLWithPath: "/tmp/exported.mov"),
        mode: .video
    )

    viewModel.send(.internal(.videoTrimExported(exportedMedia)))

    #expect(viewModel.state.capturedMedia == exportedMedia)
    #expect(coordinator.routes == [.upload])
}
