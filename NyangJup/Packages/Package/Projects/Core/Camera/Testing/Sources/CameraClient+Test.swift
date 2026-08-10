import CoreCameraInterface

public extension CameraClient {
    static var test: Self {
        #if os(iOS)
        CameraClient(
            makeController: {
                TestCameraController()
            },
            authorizationStatus: { .authorized },
            requestAccess: { true }
        )
        #else
        CameraClient()
        #endif
    }
}

#if os(iOS)
import AVFoundation
import Foundation

@MainActor
final class TestCameraController: CameraSessionControlling {
    let session = AVCaptureSession()
    var position: CameraPosition = .back
    var zoomFactor: CGFloat = 1
    var isRecording: Bool = false
    var recordedDuration: TimeInterval = 0
    private var movieContinuation: CheckedContinuation<CapturedMedia, Error>?

    func start() {}
    func stop() {}

    func switchCamera() async throws {
        position = position == .back ? .front : .back
    }

    func setZoomFactor(_ zoomFactor: CGFloat) async throws {
        self.zoomFactor = min(max(zoomFactor, 1), 3)
    }

    func capturePhoto() async throws -> CapturedMedia {
        CapturedMedia(data: Data([0, 1, 2]), mode: .photo)
    }

    func startRecording(maxDuration: TimeInterval) async throws -> CapturedMedia {
        guard !isRecording else {
            throw CameraError.alreadyRecording
        }

        isRecording = true
        return try await withCheckedThrowingContinuation {
            movieContinuation = $0
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        isRecording = false
        movieContinuation?.resume(
            returning: CapturedMedia(
                url: URL(fileURLWithPath: "/tmp/test.mov"),
                mode: .video
            )
        )
        movieContinuation = nil
    }
}
#endif
