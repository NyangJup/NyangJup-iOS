import Foundation
import AVFoundation

@MainActor
public protocol CameraSessionControlling: AnyObject {
    var session: AVCaptureSession { get }
    var position: CameraPosition { get }
    var zoomFactor: CGFloat { get }
    var isRecording: Bool { get }

    func start()
    func stop()
    func switchCamera() async throws
    func setZoomFactor(_ zoomFactor: CGFloat) async throws
    func capturePhoto() async throws -> CapturedMedia
    func startRecording() async throws
    func stopRecording() async throws -> CapturedMedia
}

public struct CameraClient: Sendable {
    public var makeController: @MainActor @Sendable () -> any CameraSessionControlling

    public init(
        makeController: @escaping @MainActor @Sendable () -> any CameraSessionControlling
    ) {
        self.makeController = makeController
    }
}
