import Foundation
import Testing
@testable import FeatureCapture
import CoreCameraInterface
import CoreCameraTesting

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
    let viewModel = CaptureViewModel(
        cameraClient: .test,
        videoTrimClient: VideoTrimClient(),
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
