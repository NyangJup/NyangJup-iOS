import CoreCameraInterface

public extension CameraClient {
    static var test: Self {
        #if os(iOS)
        CameraClient {
            TestCameraController()
        }
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

    func startRecording() async throws {
        isRecording = true
    }

    func stopRecording() async throws -> CapturedMedia {
        isRecording = false
        return CapturedMedia(url: URL(fileURLWithPath: "/tmp/test.mov"), mode: .video)
    }
}
#endif
