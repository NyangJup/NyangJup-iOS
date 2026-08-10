import Foundation
import AVFoundation

@MainActor
public protocol CameraSessionControlling: AnyObject {
    var session: AVCaptureSession { get }
    var position: CameraPosition { get }
    var zoomFactor: CGFloat { get }
    var isRecording: Bool { get }
    var recordedDuration: TimeInterval { get }

    func start()
    func stop()
    func switchCamera() async throws
    func setZoomFactor(_ zoomFactor: CGFloat) async throws
    func capturePhoto() async throws -> CapturedMedia
    func startRecording(maxDuration: TimeInterval) async throws -> CapturedMedia
    func stopRecording()
}

public struct CameraClient: Sendable {
    public var makeController: @MainActor @Sendable () -> any CameraSessionControlling
    public var authorizationStatus: @Sendable () -> AVAuthorizationStatus
    public var requestAccess: @Sendable () async -> Bool

    public init(
        makeController: @escaping @MainActor @Sendable () -> any CameraSessionControlling,
        authorizationStatus: @escaping @Sendable () -> AVAuthorizationStatus,
        requestAccess: @escaping @Sendable () async -> Bool
    ) {
        self.makeController = makeController
        self.authorizationStatus = authorizationStatus
        self.requestAccess = requestAccess
    }
}
