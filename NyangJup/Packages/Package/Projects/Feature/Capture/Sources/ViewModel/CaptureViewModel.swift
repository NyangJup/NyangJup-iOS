//
//  CaptureViewModel.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import Foundation
import _PhotosUI_SwiftUI
import UniformTypeIdentifiers

import CoreCameraInterface
import DomainCatsInterface
import DomainMediaInterface
import FeatureCommonInterface
import FeatureCaptureInterface

@MainActor
@Observable
public final class CaptureViewModel: NZViewModel {
    public struct State {
        public var mode: CaptureMode = .photo
        public var position: CameraPosition = .back
        public var zoomFactor: CGFloat = 1
        public var isRecording: Bool?
        public var capturedMedia: CapturedMedia?
        public var showsModePicker: Bool
        public var showsConfirmSheet: Bool = false
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
            case closeButtonTapped
        }

        public enum Internal {
            case captureCompleted(CapturedMedia)
            
            case videoTrimLoaded(VideoTrimState)
            case videoTrimChanged(VideoTrimState)
            case videoTrimExported(CapturedMedia)
        }
    }

    public var state: State

    let cameraClient: any CameraSessionControlling
    let mediaClient: MediaClient
    let videoTrimClient: VideoTrimClient
    private let onComplete: @MainActor @Sendable (CapturedMedia, Media) -> Void
    private let onClose: @MainActor @Sendable () -> Void
    
    public init(
        cameraClient: CameraClient,
        mediaClient: MediaClient,
        videoTrimClient: VideoTrimClient,
        configuration: CaptureConfiguration,
        onComplete: @escaping @MainActor @Sendable (CapturedMedia, Media) -> Void,
        onClose: @escaping @MainActor @Sendable () -> Void
    ) {
        self.cameraClient = cameraClient.makeController()
        self.mediaClient = mediaClient
        self.videoTrimClient = videoTrimClient
        self.state = State(configuration: configuration)
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
            cameraClient.start()
            
        case .onDisappear:
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
            state.capturedMedia = nil
            state.videoTrimState = nil
            state.isRecording = nil
            state.isPreparingMedia = false
            
        case let .photoPickerChanged(item):
            guard let item else { return }
            let isVideo = item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) })
            state.isPreparingMedia = isVideo

            Task {
                guard let data = try? await item.loadTransferable(type: Data.self) else {
                    state.isPreparingMedia = false
                    return
                }

                if isVideo {
                    let url = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension("mov")
                    guard (try? data.write(to: url, options: .atomic)) != nil else {
                        state.isPreparingMedia = false
                        return
                    }
                    self.send(.internal(.captureCompleted(CapturedMedia(url: url, mode: .video))))
                } else {
                    self.send(.internal(.captureCompleted(CapturedMedia(data: data, mode: .photo))))
                }
            }

        case .useButtonTapped:
            state.showsConfirmSheet = true
            
        case .completeButtonTapped:
            completeCapture()

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
                    defer { state.isPreparingMedia = false }

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

        case let .videoTrimExported(media):
            state.capturedMedia = media
            uploadMedia(media)
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
        state.isUploading = true

        guard media.mode == .video else {
            uploadMedia(media)
            return
        }

        guard let sourceURL = media.url,
              let trimState = state.videoTrimState else {
            state.isUploading = false
            return
        }

        let videoTrimClient = videoTrimClient
        Task {
            do {
                let outputURL = try await videoTrimClient.exportTrimmedVideo(
                    sourceURL: sourceURL,
                    startTime: trimState.startTime,
                    endTime: trimState.endTime
                )
                send(.internal(.videoTrimExported(CapturedMedia(url: outputURL, mode: .video))))
            } catch {
                state.isUploading = false
            }
        }
    }

    func uploadMedia(_ media: CapturedMedia) {
        let mediaType = switch media.mode {
        case .photo: "PHOTO"
        case .video: "VIDEO"
        }
        let mediaClient = mediaClient
        let cat = state.cat
        let catId = state.catId
        let editingMediaId = state.editingMediaId
        let comment = state.commentText

        Task {
            defer { state.isUploading = false }

            do {
                let uploadURLResponse = try await mediaClient.fetchUploadURL(
                    FetchUploadURLRequestDTO(
                        catId: catId,
                        mediaType: mediaType
                    )
                )
                let request = UploadMediaRequestDTO(
                    catId: catId,
                    fileName: uploadURLResponse.fileName,
                    mediaType: mediaType,
                    place: cat?.place,
                    comment: comment
                )
                let response = if let editingMediaId {
                    try await mediaClient.updateMedia(editingMediaId, request)
                } else {
                    try await mediaClient.uploadMedia(request)
                }
                guard let responseCatId = response.catId ?? catId else {
                    return
                }
                onComplete(
                    media,
                    Media(
                        id: response.mediaId,
                        catId: responseCatId,
                        userId: response.userId,
                        comment: response.comment,
                        thumbnailURL: response.thumbnailURL,
                        mediaType: media.mode == .photo ? .photo : .video,
                        mediaURL: response.mediaURL
                    )
                )
            } catch {

            }
        }
    }
}
