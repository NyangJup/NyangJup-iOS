//
//  CaptureViewModel.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import AVFoundation
import Foundation
import _PhotosUI_SwiftUI
import UIKit
import UniformTypeIdentifiers

import CoreCameraInterface
import CoreVideoInterface
import DomainCatsInterface
import DomainMediaInterface
import FeatureCommonInterface
import FeatureCaptureInterface

@MainActor
@Observable
public final class CaptureViewModel: NZViewModel {
    private enum MediaProcessingError: Error {
        case failed
        case timedOut
    }

    private struct PendingRegistration {
        let media: CapturedMedia
        let request: UploadMediaRequestDTO
        var registeredMedia: Media?
    }

    nonisolated private static let processingPollAttemptCount = 240
    nonisolated private static let processingPollInterval: Duration = .milliseconds(500)

    public struct State {
        public var mode: CaptureMode = .photo
        public var position: CameraPosition = .back
        public var zoomFactor: CGFloat = 1
        public var isRecording: Bool?
        public var capturedMedia: CapturedMedia?
        public let usage: CaptureUsage
        public var showsModePicker: Bool
        public var showsConfirmSheet: Bool = false
        public var isCameraPermissionAlertPresented: Bool = false
        public var isUploadFailureAlertPresented: Bool = false
        public var isUploading: Bool = false
        public var isPreparingMedia: Bool = false
        public let cat: Cat?
        public let catId: String?
        public let editingMediaId: String?
        
        public var commentText: String
        
        var videoTrimState: VideoTrimState?
        var isVideoTrimming: Bool {
            videoTrimState != nil
        }
        
        public var hasResultMedia: Bool {
            capturedMedia != nil
        }

        public var showsLoadingOverlay: Bool {
            isUploading || isPreparingMedia
        }
        
        public init(configuration: CaptureConfiguration) {
            self.usage = configuration.usage
            self.showsModePicker = configuration.showsModePicker
            self.cat = configuration.cat
            self.catId = configuration.cat?.id ?? configuration.catId
            self.editingMediaId = configuration.editingMediaId
            self.commentText = configuration.mediaComment ?? ""
        }
    }

    public enum Action {
        case view(View)
        case `internal`(Internal)

        public enum View {
            case onAppear
            case appBecameActive
            case onDisappear
            case modeChanged(CaptureMode)
            case zoomChanged(CGFloat)
            case switchCameraButtonTapped
            case captureButtonTapped
            case retakeButtonTapped
            case photoPickerChanged(PhotosPickerItem?)
            case useButtonTapped
            case durationStartTimeChanged(Double)
            case durationEndTimeChanged(Double)
            case currentTimeChanged(Double)
            case completeButtonTapped
            case retryUploadButtonTapped
            case closeButtonTapped
        }

        public enum Internal {
            case captureCompleted(CapturedMedia)
            
            case videoTrimLoaded(VideoTrimState)
            case videoTrimChanged(VideoTrimState)
        }
    }

    public var state: State

    let cameraClient: any CameraSessionControlling
    let mediaClient: MediaClient
    let videoTrimClient: VideoTrimClient
    private let cameraAuthorizationStatus: @Sendable () -> AVAuthorizationStatus
    private let requestCameraAccess: @Sendable () async -> Bool
    private let onUpload: @MainActor @Sendable (VideoUploadRequest) -> Void
    private let onComplete: @MainActor @Sendable (CapturedMedia, Media?) -> Void
    private let onClose: @MainActor @Sendable () -> Void
    private var uploadTask: Task<Void, Never>?
    private var pendingRegistration: PendingRegistration?
    
    public init(
        cameraClient: CameraClient,
        mediaClient: MediaClient,
        videoTrimClient: VideoTrimClient,
        configuration: CaptureConfiguration,
        onUpload: @escaping @MainActor @Sendable (VideoUploadRequest) -> Void = { _ in },
        onComplete: @escaping @MainActor @Sendable (CapturedMedia, Media?) -> Void,
        onClose: @escaping @MainActor @Sendable () -> Void,
    ) {
        self.cameraClient = cameraClient.makeController()
        self.cameraAuthorizationStatus = cameraClient.authorizationStatus
        self.requestCameraAccess = cameraClient.requestAccess
        self.mediaClient = mediaClient
        self.videoTrimClient = videoTrimClient
        self.state = State(configuration: configuration)
        self.onUpload = onUpload
        self.onComplete = onComplete
        self.onClose = onClose
    }

    public func send(_ action: Action) {
        switch action {
        case let .view(viewAction):
            handleViewAction(viewAction)
            
        case let .internal(internalAction):
            handleInternalAction(internalAction)
        }
    }

    public static func clampedZoomFactor(_ zoomFactor: CGFloat) -> CGFloat {
        min(max(zoomFactor, 1), 3)
    }
}

private extension CaptureViewModel {
    func handleViewAction(_ action: Action.View) {
        switch action {
        case .onAppear:
            prepareCamera()

        case .appBecameActive:
            prepareCamera()
            
        case .onDisappear:
            cancelUploadAndCleanUp()
            cameraClient.stop()
            
        case let .modeChanged(mode):
            state.mode = mode
            
        case let .zoomChanged(zoomFactor):
            let clampedZoom = Self.clampedZoomFactor(zoomFactor)
            state.zoomFactor = clampedZoom
            Task {
                try? await cameraClient.setZoomFactor(clampedZoom)
            }
            
        case .switchCameraButtonTapped:
            Task {
                try? await cameraClient.switchCamera()
                state.position = cameraClient.position
                state.zoomFactor = cameraClient.zoomFactor
            }
            
        case .captureButtonTapped:
            capture()
            
        case .retakeButtonTapped:
            cancelUploadAndCleanUp()
            state.capturedMedia = nil
            state.videoTrimState = nil
            state.isRecording = nil
            state.isPreparingMedia = false
            
        case let .photoPickerChanged(item):
            guard let item else { return }
            let isVideo = item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) })
            state.isPreparingMedia = isVideo

            Task {
                if isVideo {
                    guard let video = try? await item.loadTransferable(type: PickedVideo.self) else {
                        state.isPreparingMedia = false
                        return
                    }
                    self.send(.internal(.captureCompleted(CapturedMedia(url: video.url, mode: .video))))
                } else {
                    guard let data = try? await item.loadTransferable(type: Data.self) else {
                        return
                    }
                    self.send(.internal(.captureCompleted(CapturedMedia(data: data, mode: .photo))))
                }
            }

        case .useButtonTapped:
            switch state.usage {
            case .media:
                state.showsConfirmSheet = true

            case .catRegistration:
                guard let media = state.capturedMedia else { return }
                onComplete(normalizedMedia(from: media), nil)
            }
            
        case .completeButtonTapped:
            completeCapture()

        case .retryUploadButtonTapped:
            retryUpload()

        case .closeButtonTapped:
            onClose()
            
        case let .durationStartTimeChanged(time):
            state.videoTrimState?.startTime = time
            
        case let .durationEndTimeChanged(time):
            state.videoTrimState?.endTime = time
            
        case let .currentTimeChanged(time):
            state.videoTrimState?.currentTime = time
        }
    }

    func prepareCamera() {
        switch cameraAuthorizationStatus() {
        case .authorized:
            state.isCameraPermissionAlertPresented = false
            cameraClient.start()

        case .notDetermined:
            Task {
                if await requestCameraAccess() {
                    state.isCameraPermissionAlertPresented = false
                    cameraClient.start()
                } else {
                    state.isCameraPermissionAlertPresented = true
                }
            }

        case .denied, .restricted:
            state.isCameraPermissionAlertPresented = true

        @unknown default:
            state.isCameraPermissionAlertPresented = true
        }
    }

    func handleInternalAction(_ action: Action.Internal) {
        switch action {
        case let .captureCompleted(media):
            state.capturedMedia = media
            state.mode = media.mode
            state.isRecording = media.mode == .video ? false : nil
            if media.mode == .video {
                guard let url = media.url else {
                    state.isPreparingMedia = false
                    return
                }
                let videoTrimClient = videoTrimClient
                state.isPreparingMedia = true
                
                Task {
                    defer {
                        state.isPreparingMedia = false
                    }

                    do {
                        let duration = try await videoTrimClient.loadDuration(from: url)
                        let thumbnails = try await videoTrimClient.generateThumbnails(from: url, count: 12)
                        
                        let trimState = VideoTrimState(
                            duration: duration,
                            startTime: 0,
                            endTime: min(duration, 60),
                            currentTime: 0,
                            thumbnails: thumbnails
                        )
                        
                        send(.internal(.videoTrimLoaded(trimState)))
                    } catch {

                    }
                }
            }
            
        case let .videoTrimLoaded(trimState):
            state.videoTrimState = trimState // 1

        case let .videoTrimChanged(trimState):
            state.videoTrimState = trimState // 2

        }
    }

    func capture() {
        Task {
            do {
                switch state.mode {
                case .photo:
                    let media = try await cameraClient.capturePhoto()
                    send(.internal(.captureCompleted(media)))
                    
                case .video:
                    if cameraClient.isRecording {
                        cameraClient.stopRecording()
                    } else {
                        state.isRecording = true
                        do {
                            let media = try await cameraClient.startRecording(maxDuration: 60)
                            
                            state.isRecording = false
                            send(.internal(.captureCompleted(media)))
                        } catch {
                            state.isRecording = nil
                        }
                    }
                }
            } catch {

            }
        }
    }

    func completeCapture() {
        guard !state.isUploading,
              let media = state.capturedMedia else {
            return
        }

        state.showsConfirmSheet = false

        if let request = makeVideoUploadRequest(for: media) {
            onUpload(request)
            return
        }

        state.isUploading = true

        uploadTask = Task { [weak self] in
            guard let self else { return }
            await performUpload(for: media)
        }
    }

    func makeVideoUploadRequest(for media: CapturedMedia) -> VideoUploadRequest? {
        guard state.usage == .media,
              media.mode == .video,
              let sourceURL = media.url,
              let trimState = state.videoTrimState else {
            return nil
        }

        return VideoUploadRequest(
            sourceURL: sourceURL,
            trimStartTime: trimState.startTime,
            trimEndTime: trimState.endTime,
            catID: state.catId,
            place: state.cat?.place,
            comment: state.commentText
        )
    }

    func performUpload(for media: CapturedMedia) async {
        do {
            try Task.checkCancellation()
            let uploadedMedia = try await uploadMedia(media)
            pendingRegistration = nil
            finishUpload(success: true)
            onComplete(media, uploadedMedia)
        } catch is CancellationError {
            finishUpload(success: false, showFailure: false)
        } catch {
            finishUpload(success: false, showFailure: true)
        }
    }

    func uploadMedia(_ media: CapturedMedia) async throws -> Media {
        guard media.mode == .photo else { throw CancellationError() }

        let mediaType: MediaType = .photo
        let cat = state.cat
        let catId = state.catId
        let editingMediaId = state.editingMediaId
        let comment = state.commentText
        let uploadURLResponse = try await mediaClient.fetchUploadURL(
            FetchUploadURLRequestDTO(
                catId: catId,
                mediaType: mediaType.rawValue
            )
        )
        guard let uploadSource = uploadSource(for: media) else {
            throw CancellationError()
        }
        try await mediaClient.uploadToPresignedURL(
            uploadURLResponse,
            uploadSource,
            mediaType
        )

        let request = UploadMediaRequestDTO(
            catId: catId,
            fileName: uploadURLResponse.fileName,
            thumbnailFileName: uploadURLResponse.thumbnailFileName,
            mediaType: mediaType.rawValue,
            place: cat?.place,
            comment: comment
        )
        pendingRegistration = PendingRegistration(
            media: media,
            request: request,
            registeredMedia: nil
        )
        let uploadedMedia = try await registerMedia(
            request: request,
            editingMediaId: editingMediaId
        )
        pendingRegistration?.registeredMedia = uploadedMedia
        return try await waitUntilMediaIsReady(uploadedMedia)
    }

    func registerMedia(
        request: UploadMediaRequestDTO,
        editingMediaId: String?
    ) async throws -> Media {
        if let editingMediaId {
            try await mediaClient.updateMedia(editingMediaId, request)
        } else {
            try await mediaClient.registerMedia(request)
        }
    }

    func retryUpload() {
        guard !state.isUploading else { return }
        state.isUploadFailureAlertPresented = false

        guard let pendingRegistration else {
            completeCapture()
            return
        }

        state.isUploading = true
        uploadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let uploadedMedia: Media
                if let registeredMedia = pendingRegistration.registeredMedia {
                    uploadedMedia = registeredMedia
                } else {
                    uploadedMedia = try await registerMedia(
                        request: pendingRegistration.request,
                        editingMediaId: state.editingMediaId
                    )
                    self.pendingRegistration?.registeredMedia = uploadedMedia
                }
                let readyMedia = try await waitUntilMediaIsReady(uploadedMedia)
                self.pendingRegistration = nil
                finishUpload(success: true)
                onComplete(pendingRegistration.media, readyMedia)
            } catch is CancellationError {
                finishUpload(success: false, showFailure: false)
            } catch {
                finishUpload(success: false, showFailure: true)
            }
        }
    }

    func finishUpload(success: Bool, showFailure: Bool = false) {
        state.isUploading = false
        state.isUploadFailureAlertPresented = showFailure
        uploadTask = nil
    }

    func cancelUploadAndCleanUp() {
        uploadTask?.cancel()
        uploadTask = nil
        pendingRegistration = nil
        state.isUploading = false
    }

    func waitUntilMediaIsReady(_ media: Media) async throws -> Media {
        switch media.processingStatus {
        case .ready:
            return media
        case .failed:
            throw MediaProcessingError.failed
        case .processing:
            break
        }

        for attempt in 0..<Self.processingPollAttemptCount {
            try Task.checkCancellation()
            let fetchedMedia = try await mediaClient.fetchMedia(media.id)

            switch fetchedMedia.processingStatus {
            case .ready:
                return fetchedMedia
            case .failed:
                throw MediaProcessingError.failed
            case .processing:
                guard attempt < Self.processingPollAttemptCount - 1 else { break }
                try await Task.sleep(for: Self.processingPollInterval)
            }
        }

        throw MediaProcessingError.timedOut
    }

    func uploadSource(for media: CapturedMedia) -> PresignedUploadSource? {
        normalizedMedia(from: media).data.map(PresignedUploadSource.data)
    }

    func normalizedMedia(from media: CapturedMedia) -> CapturedMedia {
        guard media.mode == .photo else { return media }
        guard let data = media.data,
              let image = UIImage(data: data),
              let jpegData = image.jpegData(compressionQuality: 0.9) else {
            return media
        }
        return CapturedMedia(data: jpegData, mode: .photo)
    }
}
