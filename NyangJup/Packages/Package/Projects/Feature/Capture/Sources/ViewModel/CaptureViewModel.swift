//
//  CaptureViewModel.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import Foundation
import _PhotosUI_SwiftUI

import CoreCameraInterface
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
        var pendingCompletionMedia: CapturedMedia?
        
        var videoTrimState: VideoTrimState?
        var isVideoTrimming: Bool {
            videoTrimState != nil
        }
        
        public var previewImageData: Data? {
            capturedMedia?.data
        }
        
        public var hasResultMedia: Bool {
            capturedMedia != nil
        }
        
        public init(configuration: CaptureConfiguration) {
            self.showsModePicker = configuration.showsModePicker
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
        }

        public enum Internal {
            case captureCompleted(CapturedMedia)
            
            case videoTrimLoaded(VideoTrimState)
            case videoTrimChanged(VideoTrimState)
            case videoTrimExported(CapturedMedia)
            case completionDelivered
        }
    }

    public var state: State

    let cameraClient: any CameraSessionControlling
    let videoTrimClient: VideoTrimClient
    
    public init(
        cameraClient: CameraClient,
        videoTrimClient: VideoTrimClient,
        configuration: CaptureConfiguration
    ) {
        self.cameraClient = cameraClient.makeController()
        self.videoTrimClient = videoTrimClient
        self.state = State(configuration: configuration)
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
            state.pendingCompletionMedia = nil
            
        case let .photoPickerChanged(item):
            guard let item else { return }
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self) else {
                    return
                }

                await MainActor.run {
                    self.state.capturedMedia = CapturedMedia(data: data, mode: .photo)
                }
            }

        case .useButtonTapped:
            completeCapture()
            
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
            if media.mode == .video {
                guard let url = media.url else { return }
                let videoTrimClient = videoTrimClient
                
                Task {
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
                }
            }
            
        case let .videoTrimLoaded(trimState):
            state.videoTrimState = trimState // 1

        case let .videoTrimChanged(trimState):
            state.videoTrimState = trimState // 2

        case let .videoTrimExported(media):
            state.pendingCompletionMedia = media

        case .completionDelivered:
            state.pendingCompletionMedia = nil
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
                        let media = try await cameraClient.stopRecording()
                        state.isRecording = false
                        send(.internal(.captureCompleted(media)))
                    } else {
                        try await cameraClient.startRecording()
                        state.isRecording = true
                    }
                }
            } catch {

            }
        }
    }

    func completeCapture() {
        guard let media = state.capturedMedia else { return }
        guard media.mode == .video,
              let sourceURL = media.url,
              let trimState = state.videoTrimState else {
            state.pendingCompletionMedia = media
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

            }
        }
    }
}
