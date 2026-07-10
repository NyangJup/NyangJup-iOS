//
//  CaptureView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import SwiftUI

import FeatureCaptureInterface

public struct CaptureView: View {
    @State private var viewModel: CaptureViewModel
    private let onAction: @MainActor @Sendable (CaptureDelegate.Action) -> Void

    
    public init(
        viewModel: CaptureViewModel,
        onAction: @escaping @MainActor @Sendable (CaptureDelegate.Action) -> Void
    ) {
        self.viewModel = viewModel
        self.onAction = onAction
    }

    public var body: some View {
        VStack(spacing: 0) {
            CapturePreviewView(
                previewImageData: viewModel.state.previewImageData,
                capturedMediaURL: viewModel.state.capturedMedia?.url,
                hasResultMedia: viewModel.state.hasResultMedia,
                isRecording: viewModel.state.isRecording,
                zoomFactor: viewModel.state.zoomFactor,
                trimStartTime: Binding(
                    get: { viewModel.state.videoTrimState?.startTime },
                    set: {
                        guard let time = $0 else { return }
                        viewModel.send(.view(.durationStartTimeChanged(time)))
                    }
                ),
                trimEndTime: Binding(
                    get: { viewModel.state.videoTrimState?.endTime },
                    set: {
                        guard let time = $0 else { return }
                        viewModel.send(.view(.durationEndTimeChanged(time)))
                    }
                ),
                currentTime: Binding(
                    get: { viewModel.state.videoTrimState?.currentTime },
                    set: {
                        guard let time = $0 else { return }
                        viewModel.send(.view(.currentTimeChanged(time)))
                    }
                ),
                cameraController: viewModel.cameraClient,
                onZoomChanged: { viewModel.send(.view(.zoomChanged($0))) }
            )

            bottomArea
        }
        .background(.black)
        .overlay(alignment: .topTrailing) {
            dismissButton
        }
        .onChange(of: viewModel.state.pendingCompletionMedia) { _, media in
            guard let media else { return }
            onAction(.captured(media))
            viewModel.send(.internal(.completionDelivered))
        }
        .onAppear {
            viewModel.send(.view(.onAppear))
        }
        .onDisappear {
            viewModel.send(.view(.onDisappear))
        }
    }
}


// MARK: - View
private extension CaptureView {
    @ViewBuilder
    var bottomArea: some View {
        let viewModel = viewModel
        let videoTrimState = viewModel.state.videoTrimState
        let showsVideoTrimBar = viewModel.state.isRecording == false

        if viewModel.state.hasResultMedia {
            CaptureResultBottomBar(
                mode: viewModel.state.mode,
                capturedMedia: viewModel.state.capturedMedia,
                trimThumbnails: showsVideoTrimBar ? videoTrimState?.thumbnails : nil,
                trimDuration: showsVideoTrimBar ? videoTrimState?.duration : nil,
                trimStartTime: Binding(
                    get: { [weak viewModel] in
                        guard let viewModel else { return 0 }
                        return viewModel.state.videoTrimState?.startTime ?? 0
                    },
                    set: { [weak viewModel] in
                        guard let viewModel else { return }
                        viewModel.send(.view(.durationStartTimeChanged($0)))
                    }
                ),
                trimEndTime: Binding(
                    get: { [weak viewModel] in
                        guard let viewModel else { return 0 }
                        return viewModel.state.videoTrimState?.endTime ?? 0
                    },
                    set: { [weak viewModel] in
                        guard let viewModel else { return }
                        viewModel.send(.view(.durationEndTimeChanged($0)))
                    }
                ),
                trimCurrentTime: Binding(
                    get: { [weak viewModel] in
                        guard let viewModel else { return 0 }
                        return viewModel.state.videoTrimState?.currentTime ?? 0
                    },
                    set: { [weak viewModel] in
                        guard let viewModel else { return }
                        viewModel.send(.view(.currentTimeChanged($0)))
                    }
                ),
                onRetake: { viewModel.send(.view(.retakeButtonTapped)) },
                onComplete: { viewModel.send(.view(.useButtonTapped)) }
            )
        } else {
            CameraControlBar(
                mode: Binding(
                    get: { viewModel.state.mode },
                    set: { viewModel.send(.view(.modeChanged($0))) }
                ),
                isRecording: viewModel.state.isRecording,
                showsModePicker: viewModel.state.showsModePicker,
                onPhotoPickerChanged: { viewModel.send(.view(.photoPickerChanged($0))) },
                onCapture: { viewModel.send(.view(.captureButtonTapped)) },
                onSwitchCamera: { viewModel.send(.view(.switchCameraButtonTapped)) }
            )
            .padding(.top, Constant.cameraControlTopPadding)
            .padding(.bottom, Constant.cameraControlBottomPadding)
        }
    }

    var dismissButton: some View {
        Button {
            onAction(.close)
        } label: {
            Image(systemName: Constant.dismissImage)
                .font(.system(size: Constant.dismissImageSize, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: Constant.dismissButtonSize, height: Constant.dismissButtonSize)
        }
        .padding(.top, Constant.dismissButtonTopPadding)
    }
}

// MARK: - Constant
private extension CaptureView {
    enum Constant {
        static let dismissImage = "xmark"
        static let dismissImageSize: CGFloat = 18
        static let dismissButtonSize: CGFloat = 52
        static let dismissButtonTopPadding: CGFloat = 16
        static let cameraControlTopPadding: CGFloat = 20
        static let cameraControlBottomPadding: CGFloat = 10
    }
}
