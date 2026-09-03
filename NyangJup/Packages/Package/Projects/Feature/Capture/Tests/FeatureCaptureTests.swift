//
//  FeatureCaptureTests.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import AVFoundation
import Foundation
import Testing
import UIKit
@testable import FeatureCapture
import CoreCameraInterface
import CoreCameraTesting
import DomainCatsInterface
import DomainMediaInterface
import DomainMediaTesting
import FeatureCaptureInterface

@MainActor
private final class CaptureOutputSpy {
    var completedMedia: CapturedMedia?
    var uploadedMedia: Media?
    var completionCount = 0
    var didClose = false

    func complete(capturedMedia: CapturedMedia, uploadedMedia: Media?) {
        self.completedMedia = capturedMedia
        self.uploadedMedia = uploadedMedia
        completionCount += 1
    }
}

private actor UploadFlowStub {
    private(set) var fetchRequests: [FetchUploadURLRequestDTO] = []
    private(set) var uploadRequests: [UploadMediaRequestDTO] = []
    private var fetchContinuation: CheckedContinuation<UploadURL, Error>?
    private var uploadContinuation: CheckedContinuation<Media, Error>?

    func fetchUploadURL(
        _ request: FetchUploadURLRequestDTO
    ) async throws -> UploadURL {
        fetchRequests.append(request)
        return try await withCheckedThrowingContinuation {
            fetchContinuation = $0
        }
    }

    func uploadMedia(
        _ request: UploadMediaRequestDTO
    ) async throws -> Media {
        uploadRequests.append(request)
        return try await withCheckedThrowingContinuation {
            uploadContinuation = $0
        }
    }

    func resumeFetch(with response: UploadURL) {
        fetchContinuation?.resume(returning: response)
        fetchContinuation = nil
    }

    func resumeUpload(with response: Media) {
        uploadContinuation?.resume(returning: response)
        uploadContinuation = nil
    }
}

private actor UpdateMediaRecorder {
    private(set) var mediaId: String?
    private(set) var request: UploadMediaRequestDTO?

    func record(
        mediaId: String,
        request: UploadMediaRequestDTO
    ) {
        self.mediaId = mediaId
        self.request = request
    }
}

@MainActor
private final class RecordingCameraController: CameraSessionControlling {
    let session = AVCaptureSession()
    var position: CameraPosition = .back
    var zoomFactor: CGFloat = 1
    private(set) var isRecording = false
    var recordedDuration: TimeInterval = 0
    private(set) var requestedMaxDurations: [TimeInterval] = []
    private(set) var startCallCount = 0
    private(set) var stopRecordingCallCount = 0
    private var continuation: CheckedContinuation<CapturedMedia, Error>?

    func start() {
        startCallCount += 1
    }
    func stop() {}
    func switchCamera() async throws {}
    func setZoomFactor(_ zoomFactor: CGFloat) async throws {}

    func capturePhoto() async throws -> CapturedMedia {
        CapturedMedia(data: Data(), mode: .photo)
    }

    func startRecording(maxDuration: TimeInterval) async throws -> CapturedMedia {
        requestedMaxDurations.append(maxDuration)
        isRecording = true

        return try await withCheckedThrowingContinuation {
            continuation = $0
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        stopRecordingCallCount += 1
        finishRecording()
    }

    func finishRecording() {
        guard isRecording else { return }

        isRecording = false
        continuation?.resume(
            returning: CapturedMedia(
                url: FileManager.default.temporaryDirectory
                    .appendingPathComponent("recorded-video.mov"),
                mode: .video
            )
        )
        continuation = nil
    }
}

private final class CameraAuthorizationStub: @unchecked Sendable {
    var status: AVAuthorizationStatus

    init(status: AVAuthorizationStatus) {
        self.status = status
    }
}

@MainActor
private func makeCameraClient(
    controller: any CameraSessionControlling,
    authorizationStatus: AVAuthorizationStatus,
    requestAccess: Bool = true
) -> CameraClient {
    CameraClient(
        makeController: { controller },
        authorizationStatus: { authorizationStatus },
        requestAccess: { requestAccess }
    )
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
func authorizedCameraStartsOnAppear() {
    let controller = RecordingCameraController()
    let viewModel = CaptureViewModel(
        cameraClient: makeCameraClient(
            controller: controller,
            authorizationStatus: .authorized
        ),
        mediaClient: .test,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(showsModePicker: true),
        onComplete: { _, _ in },
        onClose: {}
    )

    viewModel.send(.view(.onAppear))

    #expect(controller.startCallCount == 1)
    #expect(!viewModel.state.isCameraPermissionAlertPresented)
}

@MainActor
@Test
func deniedCameraPermissionPresentsAlertWithoutStartingCamera() {
    let controller = RecordingCameraController()
    let viewModel = CaptureViewModel(
        cameraClient: makeCameraClient(
            controller: controller,
            authorizationStatus: .denied
        ),
        mediaClient: .test,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(showsModePicker: true),
        onComplete: { _, _ in },
        onClose: {}
    )

    viewModel.send(.view(.onAppear))

    #expect(controller.startCallCount == 0)
    #expect(viewModel.state.isCameraPermissionAlertPresented)
}

@MainActor
@Test
func authorizedCameraAfterReturningFromSettingsDismissesAlertAndStartsCamera() {
    let controller = RecordingCameraController()
    let authorization = CameraAuthorizationStub(status: .denied)
    let cameraClient = CameraClient(
        makeController: { controller },
        authorizationStatus: { authorization.status },
        requestAccess: { false }
    )
    let viewModel = CaptureViewModel(
        cameraClient: cameraClient,
        mediaClient: .test,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(showsModePicker: true),
        onComplete: { _, _ in },
        onClose: {}
    )

    viewModel.send(.view(.onAppear))
    #expect(viewModel.state.isCameraPermissionAlertPresented)
    #expect(controller.startCallCount == 0)

    authorization.status = .authorized
    viewModel.send(.view(.appBecameActive))

    #expect(!viewModel.state.isCameraPermissionAlertPresented)
    #expect(controller.startCallCount == 1)
}

@MainActor
@Test
func newlyGrantedCameraPermissionStartsCamera() async {
    let controller = RecordingCameraController()
    let viewModel = CaptureViewModel(
        cameraClient: makeCameraClient(
            controller: controller,
            authorizationStatus: .notDetermined
        ),
        mediaClient: .test,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(showsModePicker: true),
        onComplete: { _, _ in },
        onClose: {}
    )

    viewModel.send(.view(.onAppear))
    await waitUntil { controller.startCallCount == 1 }

    #expect(!viewModel.state.isCameraPermissionAlertPresented)
}

@MainActor
@Test
func newlyDeniedCameraPermissionPresentsAlert() async {
    let controller = RecordingCameraController()
    let viewModel = CaptureViewModel(
        cameraClient: makeCameraClient(
            controller: controller,
            authorizationStatus: .notDetermined,
            requestAccess: false
        ),
        mediaClient: .test,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(showsModePicker: true),
        onComplete: { _, _ in },
        onClose: {}
    )

    viewModel.send(.view(.onAppear))
    await waitUntil { viewModel.state.isCameraPermissionAlertPresented }

    #expect(controller.startCallCount == 0)
}

@MainActor
@Test
func captureViewModelUpdatesCaptureState() {
    let outputSpy = CaptureOutputSpy()
    let viewModel = CaptureViewModel(
        cameraClient: .test,
        mediaClient: .test,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(
            showsModePicker: false,
            cat: nil
        ),
        onComplete: { outputSpy.complete(capturedMedia: $0, uploadedMedia: $1) },
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
func catRegistrationUseCompletesWithCapturedMediaWithoutPresentingConfirmation() {
    let outputSpy = CaptureOutputSpy()
    let viewModel = CaptureViewModel(
        cameraClient: .test,
        mediaClient: .test,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(
            usage: .catRegistration,
            showsModePicker: false
        ),
        onComplete: { outputSpy.complete(capturedMedia: $0, uploadedMedia: $1) },
        onClose: {}
    )
    let media = CapturedMedia(data: Data([0, 1, 2]), mode: .photo)

    viewModel.send(.internal(.captureCompleted(media)))
    viewModel.send(.view(.useButtonTapped))

    #expect(outputSpy.completionCount == 1)
    #expect(outputSpy.completedMedia?.data == media.data)
    #expect(outputSpy.uploadedMedia == nil)
    #expect(!viewModel.state.showsConfirmSheet)
}

@MainActor
@Test
func completingPhotoWaitsForBothUploadRequests() async {
    let outputSpy = CaptureOutputSpy()
    let uploadFlow = UploadFlowStub()
    let cat = Cat(
        id: "cat-id",
        name: "나비",
        place: "우리 집",
        imageURL: "https://example.com/cats/cat-1.png"
    )
    var mediaClient = MediaClient.test
    mediaClient.fetchUploadURL = {
        try await uploadFlow.fetchUploadURL($0)
    }
    mediaClient.uploadMedia = {
        try await uploadFlow.uploadMedia($0)
    }
    let viewModel = CaptureViewModel(
        cameraClient: .test,
        mediaClient: mediaClient,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(
            showsModePicker: true,
            cat: cat
        ),
        onComplete: { outputSpy.complete(capturedMedia: $0, uploadedMedia: $1) },
        onClose: {}
    )
    let media = CapturedMedia(
        data: Data([0, 1, 2]),
        mode: .photo
    )
    viewModel.state.commentText = "귀여워"
    #expect(viewModel.state.catId == cat.id)

    viewModel.send(.internal(.captureCompleted(media)))
    viewModel.send(.view(.useButtonTapped))
    #expect(viewModel.state.showsConfirmSheet)

    viewModel.send(.view(.completeButtonTapped))
    await waitUntilAsync { await uploadFlow.fetchRequests.count == 1 }

    #expect(viewModel.state.showsConfirmSheet == false)
    #expect(viewModel.state.isUploading)
    #expect(viewModel.state.showsLoadingOverlay)
    #expect(outputSpy.completionCount == 0)
    let fetchRequest = await uploadFlow.fetchRequests.first
    #expect(fetchRequest?.catId == cat.id)
    #expect(fetchRequest?.mediaType == "PHOTO")

    viewModel.send(.view(.completeButtonTapped))
    await Task.yield()
    #expect(await uploadFlow.fetchRequests.count == 1)

    await uploadFlow.resumeFetch(
        with: UploadURL(
            uploadURL: "https://example.com/upload",
            fileName: "photo.jpg"
        )
    )
    await waitUntilAsync { await uploadFlow.uploadRequests.count == 1 }

    #expect(outputSpy.completionCount == 0)
    let uploadRequest = await uploadFlow.uploadRequests.first
    #expect(uploadRequest?.catId == cat.id)
    #expect(uploadRequest?.fileName == "photo.jpg")
    #expect(uploadRequest?.mediaType == "PHOTO")
    #expect(uploadRequest?.place == cat.place)
    #expect(uploadRequest?.comment == "귀여워")

    await uploadFlow.resumeUpload(
        with: Media(
            id: "uploaded-media",
            catId: cat.id,
            userId: "test-user-id",
            comment: "귀여워",
            thumbnailURL: "https://example.com/thumbnail/photo.jpg",
            mediaType: .photo,
            mediaURL: "https://example.com/media/photo.jpg"
        )
    )
    await waitUntil { outputSpy.completionCount == 1 }

    #expect(outputSpy.completedMedia == media)
    #expect(outputSpy.uploadedMedia?.id == "uploaded-media")
    #expect(outputSpy.uploadedMedia?.mediaType == .photo)
    #expect(viewModel.state.isUploading == false)
    #expect(viewModel.state.showsLoadingOverlay == false)
}

@MainActor
@Test
func editingCaptureUsesUpdateMediaAndKeepsMediaId() async {
    let outputSpy = CaptureOutputSpy()
    let recorder = UpdateMediaRecorder()
    var mediaClient = MediaClient.test
    mediaClient.fetchUploadURL = { _ in
        UploadURL(
            uploadURL: "https://example.com/upload",
            fileName: "updated-photo.jpg"
        )
    }
    mediaClient.updateMedia = { mediaId, request in
        await recorder.record(mediaId: mediaId, request: request)
        return Media(
            id: mediaId,
            catId: request.catId,
            userId: "current-user",
            comment: request.comment,
            thumbnailURL: "https://example.com/thumbnail/updated-photo.jpg",
            mediaType: MediaType(rawValue: request.mediaType) ?? .photo,
            mediaURL: "https://example.com/media/updated-photo.jpg"
        )
    }
    let viewModel = CaptureViewModel(
        cameraClient: .test,
        mediaClient: mediaClient,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(
            showsModePicker: true,
            catId: "cat-id",
            editingMediaId: "media-id",
            mediaComment: "기존 메모"
        ),
        onComplete: { outputSpy.complete(capturedMedia: $0, uploadedMedia: $1) },
        onClose: {}
    )
    let media = CapturedMedia(
        data: Data([0, 1, 2]),
        mode: .photo
    )

    #expect(viewModel.state.commentText == "기존 메모")

    viewModel.send(.internal(.captureCompleted(media)))
    viewModel.send(.view(.completeButtonTapped))
    await waitUntil { outputSpy.completionCount == 1 }

    let updatedMediaId = await recorder.mediaId
    let updateRequest = await recorder.request
    #expect(updatedMediaId == "media-id")
    #expect(updateRequest?.catId == "cat-id")
    #expect(updateRequest?.comment == "기존 메모")
    #expect(outputSpy.uploadedMedia?.id == "media-id")
}

@MainActor
@Test
func capturedVideoSynchronizesModeAndPreparingState() async {
    let outputSpy = CaptureOutputSpy()
    let viewModel = CaptureViewModel(
        cameraClient: .test,
        mediaClient: .test,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(
            showsModePicker: true,
            cat: nil
        ),
        onComplete: { outputSpy.complete(capturedMedia: $0, uploadedMedia: $1) },
        onClose: {}
    )
    let selectedVideo = CapturedMedia(
        url: FileManager.default.temporaryDirectory
            .appendingPathComponent("missing-selected-video.mov"),
        mode: .video
    )

    viewModel.send(.internal(.captureCompleted(selectedVideo)))

    #expect(viewModel.state.capturedMedia == selectedVideo)
    #expect(viewModel.state.mode == .video)
    #expect(viewModel.state.isRecording == false)
    #expect(viewModel.state.isPreparingMedia)
    #expect(viewModel.state.showsLoadingOverlay)

    await waitUntil { viewModel.state.isPreparingMedia == false }
    #expect(viewModel.state.showsLoadingOverlay == false)
    #expect(outputSpy.completionCount == 0)
}

@MainActor
@Test
func videoCaptureRequestsSixtySecondLimitAndCompletesAutomatically() async {
    let controller = RecordingCameraController()
    let viewModel = CaptureViewModel(
        cameraClient: makeCameraClient(
            controller: controller,
            authorizationStatus: .authorized
        ),
        mediaClient: .test,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(showsModePicker: true),
        onComplete: { _, _ in },
        onClose: {}
    )
    viewModel.send(.view(.modeChanged(.video)))

    viewModel.send(.view(.captureButtonTapped))
    await waitUntil { controller.isRecording }

    #expect(viewModel.state.isRecording == true)
    #expect(controller.requestedMaxDurations == [60])
    #expect(controller.stopRecordingCallCount == 0)

    controller.finishRecording()
    await waitUntil { viewModel.state.capturedMedia != nil }

    #expect(viewModel.state.isRecording == false)
    #expect(viewModel.state.capturedMedia?.mode == .video)
    #expect(controller.stopRecordingCallCount == 0)
}

@MainActor
@Test
func videoCaptureCanStopManuallyBeforeSixtySeconds() async {
    let controller = RecordingCameraController()
    let viewModel = CaptureViewModel(
        cameraClient: makeCameraClient(
            controller: controller,
            authorizationStatus: .authorized
        ),
        mediaClient: .test,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(showsModePicker: true),
        onComplete: { _, _ in },
        onClose: {}
    )
    viewModel.send(.view(.modeChanged(.video)))

    viewModel.send(.view(.captureButtonTapped))
    await waitUntil { controller.isRecording }
    controller.recordedDuration = 12.5

    viewModel.send(.view(.captureButtonTapped))
    await waitUntil { viewModel.state.capturedMedia != nil }

    #expect(controller.requestedMaxDurations == [60])
    #expect(controller.stopRecordingCallCount == 1)
    #expect(controller.recordedDuration == 12.5)
    #expect(viewModel.state.isRecording == false)
    #expect(viewModel.state.capturedMedia?.mode == .video)
}

@MainActor
@Test
func photoUploadSourceNormalizesImageDataToJPEG() throws {
    let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
        UIColor.systemBlue.setFill()
        context.cgContext.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
    }
    let pngData = try #require(image.pngData())
    let outputSpy = CaptureOutputSpy()
    let viewModel = CaptureViewModel(
        cameraClient: .test,
        mediaClient: .test,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(
            usage: .catRegistration,
            showsModePicker: false
        ),
        onComplete: { outputSpy.complete(capturedMedia: $0, uploadedMedia: $1) },
        onClose: {}
    )

    viewModel.send(.internal(.captureCompleted(
        CapturedMedia(data: pngData, mode: .photo)
    )))
    viewModel.send(.view(.useButtonTapped))
    let data = try #require(outputSpy.completedMedia?.data)

    #expect(Array(data.prefix(3)) == [0xFF, 0xD8, 0xFF])
}

@MainActor
@Test
func presignedUploadFailurePresentsAlertAndKeepsCaptureResult() async {
    let outputSpy = CaptureOutputSpy()
    var mediaClient = MediaClient.test
    mediaClient.uploadToPresignedURL = { _, _, _ in
        throw CancellationError()
    }
    let viewModel = CaptureViewModel(
        cameraClient: .test,
        mediaClient: mediaClient,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(
            showsModePicker: true,
            cat: Cat(id: "cat-1", name: "나비", place: "서울숲", imageURL: "")
        ),
        onComplete: { outputSpy.complete(capturedMedia: $0, uploadedMedia: $1) },
        onClose: {}
    )
    let media = CapturedMedia(data: Data([1, 2, 3]), mode: .photo)
    viewModel.send(.internal(.captureCompleted(media)))
    viewModel.send(.view(.useButtonTapped))
    viewModel.send(.view(.completeButtonTapped))

    await waitUntil { viewModel.state.isUploadFailureAlertPresented }

    #expect(viewModel.state.capturedMedia == media)
    #expect(!viewModel.state.showsLoadingOverlay)
    #expect(outputSpy.completionCount == 0)
}

@MainActor
@Test
func processingVideoCompletesAfterReadyHLSURLIsFetched() async {
    let outputSpy = CaptureOutputSpy()
    var mediaClient = MediaClient.test
    mediaClient.uploadMedia = { request in
        Media(
            id: "video-1",
            catId: request.catId,
            userId: "user-1",
            comment: request.comment,
            thumbnailURL: nil,
            mediaType: .video,
            mediaURL: nil,
            processingStatus: .processing
        )
    }
    mediaClient.fetchMedia = { id in
        Media(
            id: id,
            catId: "cat-1",
            userId: "user-1",
            comment: "",
            thumbnailURL: "https://cdn.example.com/video.jpg",
            mediaType: .video,
            mediaURL: "https://cdn.example.com/video.m3u8",
            processingStatus: .ready
        )
    }
    let viewModel = CaptureViewModel(
        cameraClient: .test,
        mediaClient: mediaClient,
        videoTrimClient: VideoTrimClient(),
        configuration: .init(
            showsModePicker: true,
            cat: Cat(id: "cat-1", name: "나비", place: "서울숲", imageURL: "")
        ),
        onComplete: { outputSpy.complete(capturedMedia: $0, uploadedMedia: $1) },
        onClose: {}
    )
    let media = CapturedMedia(
        url: FileManager.default.temporaryDirectory.appendingPathComponent("video.mp4"),
        mode: .video
    )
    viewModel.send(.internal(.videoTrimExported(media)))

    await waitUntil { outputSpy.completionCount == 1 }

    #expect(outputSpy.uploadedMedia?.processingStatus == .ready)
    #expect(outputSpy.uploadedMedia?.mediaURL == "https://cdn.example.com/video.m3u8")
    #expect(!viewModel.state.showsLoadingOverlay)
}

@MainActor
private func waitUntil(_ condition: () -> Bool) async {
    for _ in 0..<100 {
        if condition() { return }
        try? await Task.sleep(for: .milliseconds(10))
    }
}

private func waitUntilAsync(
    _ condition: @escaping @Sendable () async -> Bool
) async {
    for _ in 0..<100 {
        if await condition() { return }
        try? await Task.sleep(for: .milliseconds(10))
    }
}
