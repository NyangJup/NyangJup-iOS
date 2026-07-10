import AVFoundation
import CoreCameraInterface
import Foundation
import UIKit

public extension CameraClient {
    static var live: Self {
       CameraClient(makeController: {
           LiveCameraController()
       })
    }
}

@MainActor
final class LiveCameraController: NSObject, CameraSessionControlling {
    let session = AVCaptureSession()

    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var photoContinuation: CheckedContinuation<CapturedMedia, Error>?
    private var movieContinuation: CheckedContinuation<CapturedMedia, Error>?

    private(set) var position: CameraPosition = .back
    private(set) var zoomFactor: CGFloat = 1
    
    var isRecording: Bool {
        movieOutput.isRecording
    }

    override init() {
        super.init()
        configureSession()
    }

    func start() {
        guard !session.isRunning else { return }
        session.startRunning()
    }

    func stop() {
        guard session.isRunning else { return }
        session.stopRunning()
    }

    func switchCamera() async throws {
        let nextPosition: CameraPosition = position == .back ? .front : .back
        let devicePosition: AVCaptureDevice.Position = nextPosition == .back ? .back : .front
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: devicePosition) else {
            throw CameraError.deviceUnavailable
        }

        let input = try AVCaptureDeviceInput(device: device)

        session.beginConfiguration()
        if let currentInput {
            session.removeInput(currentInput)
        }

        guard session.canAddInput(input) else {
            session.commitConfiguration()
            throw CameraError.inputUnavailable
        }

        session.addInput(input)
        currentInput = input
        position = nextPosition
        try await setZoomFactor(1)
        session.commitConfiguration()
    }

    func setZoomFactor(_ zoomFactor: CGFloat) async throws {
        let clampedZoom = min(max(zoomFactor, 1), 3)
        guard let device = currentInput?.device else { return }

        try device.lockForConfiguration()
        device.videoZoomFactor = min(clampedZoom, device.activeFormat.videoMaxZoomFactor)
        device.unlockForConfiguration()
        self.zoomFactor = clampedZoom
    }

    func capturePhoto() async throws -> CapturedMedia {
        try await withCheckedThrowingContinuation { continuation in
            photoContinuation = continuation
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func startRecording() async throws {
        guard !movieOutput.isRecording else { return }
        
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        movieOutput.startRecording(to: url, recordingDelegate: self)
    }

    func stopRecording() async throws -> CapturedMedia {
        guard movieOutput.isRecording else {
            throw CameraError.notRecording
        }

        return try await withCheckedThrowingContinuation { continuation in
            movieContinuation = continuation
            movieOutput.stopRecording()
        }
    }
}

private extension LiveCameraController {
    func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        addInput(position: .back)
        addOutput(photoOutput)
        addOutput(movieOutput)
        session.commitConfiguration()
    }

    func addInput(position: AVCaptureDevice.Position) {
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            return
        }

        session.addInput(input)
        currentInput = input
    }

    func addOutput(_ output: AVCaptureOutput) {
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
    }
}

extension LiveCameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let data = photo.fileDataRepresentation()
        Task { @MainActor in
            if let error {
                photoContinuation?.resume(throwing: error)
                photoContinuation = nil
                return
            }

            guard let data else {
                photoContinuation?.resume(throwing: CameraError.photoDataUnavailable)
                photoContinuation = nil
                return
            }

            photoContinuation?.resume(returning: CapturedMedia(data: data, mode: .photo))
            photoContinuation = nil
        }
    }
}

extension LiveCameraController: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                movieContinuation?.resume(throwing: error)
            } else {
                movieContinuation?.resume(returning: CapturedMedia(url: outputFileURL, mode: .video))
            }
            movieContinuation = nil
        }
    }
}
