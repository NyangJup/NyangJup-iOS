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

    func complete(capturedMedia: CapturedMedia, uploadedMedia: Media) {
        self.completedMedia = capturedMedia
        self.uploadedMedia = uploadedMedia
        completionCount += 1
    }
}

private actor UploadFlowStub {
    private(set) var fetchRequests: [FetchUploadURLRequestDTO] = []
    private(set) var uploadRequests: [UploadMediaRequestDTO] = []
    private var fetchContinuation: CheckedContinuation<UploadURLResponseDTO, Error>?
    private var uploadContinuation: CheckedContinuation<UploadMediaResponseDTO, Error>?

    func fetchUploadURL(
        _ request: FetchUploadURLRequestDTO
    ) async throws -> UploadURLResponseDTO {
        fetchRequests.append(request)
        return try await withCheckedThrowingContinuation {
            fetchContinuation = $0
        }
    }

    func uploadMedia(
        _ request: UploadMediaRequestDTO
    ) async throws -> UploadMediaResponseDTO {
        uploadRequests.append(request)
        return try await withCheckedThrowingContinuation {
            uploadContinuation = $0
        }
    }

    func resumeFetch(with response: UploadURLResponseDTO) {
        fetchContinuation?.resume(returning: response)
        fetchContinuation = nil
    }

    func resumeUpload(with response: UploadMediaResponseDTO) {
        uploadContinuation?.resume(returning: response)
        uploadContinuation = nil
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
func completingPhotoWaitsForBothUploadRequests() async {
    let outputSpy = CaptureOutputSpy()
    let uploadFlow = UploadFlowStub()
    let cat = Cat(
        id: "cat-id",
        name: "나비",
        place: "우리 집",
        appearanceKey: "abyssinian"
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
        with: UploadURLResponseDTO(
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
        with: UploadMediaResponseDTO(
            catId: cat.id,
            mediaId: "uploaded-media",
            mediaType: "PHOTO",
            mediaURL: "https://example.com/media/photo.jpg",
            thumbnailURL: "https://example.com/thumbnail/photo.jpg",
            comment: "귀여워"
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
        await Task.yield()
    }
}
