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

@MainActor
private final class CaptureOutputSpy {
    var completedMedia: CapturedMedia?
    var didClose = false
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
    let outputSpy = CaptureOutputSpy()
    let viewModel = CaptureViewModel(
        cameraClient: .test,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(showsModePicker: false),
        onComplete: { outputSpy.completedMedia = $0 },
        onClose: { outputSpy.didClose = true }
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

    viewModel.send(.view(.closeButtonTapped))
    #expect(outputSpy.didClose)
}

@MainActor
@Test
func completingPhotoSendsCapturedMedia() {
    let outputSpy = CaptureOutputSpy()
    let viewModel = CaptureViewModel(
        cameraClient: .test,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(showsModePicker: true),
        onComplete: { outputSpy.completedMedia = $0 },
        onClose: {}
    )
    let media = CapturedMedia(
        data: Data([0, 1, 2]),
        mode: .photo
    )

    viewModel.send(.internal(.captureCompleted(media)))
    viewModel.send(.view(.useButtonTapped))
    viewModel.send(.view(.completeButtonTapped))

    #expect(viewModel.state.showsConfirmSheet)
    #expect(outputSpy.completedMedia == media)
}

@MainActor
@Test
func exportedVideoReplacesCapturedMediaAndCompletes() {
    let outputSpy = CaptureOutputSpy()
    let viewModel = CaptureViewModel(
        cameraClient: .test,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(showsModePicker: true),
        onComplete: { outputSpy.completedMedia = $0 },
        onClose: {}
    )
    let exportedMedia = CapturedMedia(
        url: URL(fileURLWithPath: "/tmp/exported.mov"),
        mode: .video
    )

    viewModel.send(.internal(.videoTrimExported(exportedMedia)))

    #expect(viewModel.state.capturedMedia == exportedMedia)
    #expect(outputSpy.completedMedia == exportedMedia)
}
