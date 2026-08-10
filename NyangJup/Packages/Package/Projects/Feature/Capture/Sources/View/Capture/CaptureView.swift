//
//  CaptureView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import SwiftUI
import UIKit

import SharedDesign

public struct CaptureView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewModel: CaptureViewModel

    
    public init(viewModel: CaptureViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        GeometryReader { geometry in
            Group {
                if viewModel.state.hasResultMedia {
                    resultLayout
                } else {
                    previewLayout(width: geometry.size.width)
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .clipped()
            .overlay(alignment: .topTrailing) {
                dismissButton
            }
            .overlay(alignment: .bottom) {
                if !viewModel.state.hasResultMedia, viewModel.state.mode == .video {
                    cameraControllBar
                }
            }
        }
        .background(.black)
        .onAppear {
            viewModel.send(.view(.onAppear))
        }
        .sheet(isPresented: $viewModel.state.showsConfirmSheet) {
            CaptureConfirmView(
                comment: $viewModel.state.commentText,
                onComplete: {
                    viewModel.send(.view(.completeButtonTapped))
                }
            )
        }
        .onDisappear {
            viewModel.send(.view(.onDisappear))
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            viewModel.send(.view(.appBecameActive))
        }
        .alert(
            Constant.cameraPermissionAlertTitle,
            isPresented: $viewModel.state.isCameraPermissionAlertPresented
        ) {
            Button(Constant.cancelTitle, role: .cancel) {}
            Button(Constant.openSettingsTitle) {
                guard let settingsURL = URL(
                    string: UIApplication.openSettingsURLString
                ) else { return }
                openURL(settingsURL)
            }
        } message: {
            Text(Constant.cameraPermissionAlertMessage)
        }
        .loadingOverlay(isPresented: viewModel.state.showsLoadingOverlay)
    }
}

// MARK: - View
private extension CaptureView {
    
    var resultLayout: some View {
        VStack(spacing: 0) {
            captureResultContent
                .aspectRatio(captureAspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            captureResultBar
                .padding(.top, Constant.resultControlSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func previewLayout(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            if viewModel.state.mode == .photo {
                Spacer()
            }

            capturePreivewView
                .aspectRatio(captureAspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .layoutPriority(1)

            if viewModel.state.mode == .photo {
                cameraControllBar
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Constant.previewControlSpacing)
            }
        }
        .frame(width: width)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    var captureResultContent: some View {
        if let media = viewModel.state.capturedMedia {
            CaptureResultView(
                media: media,
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
                )
            )
        }
    }
    
    var capturePreivewView: some View {
        CapturePreviewView(
            zoomFactor: viewModel.state.zoomFactor,
            cameraController: viewModel.cameraClient,
            onZoomChanged: { viewModel.send(.view(.zoomChanged($0))) },
            isRecording: viewModel.state.isRecording ?? false
        )
    }
    
    @ViewBuilder
    var captureResultBar: some View {
        let videoTrimState = viewModel.state.videoTrimState
        let capturedMode = viewModel.state.capturedMedia?.mode ?? viewModel.state.mode
        let showsVideoTrimBar = capturedMode == .video
        
        CaptureResultBottomBar(
            mode: capturedMode,
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
    }
    
    var cameraControllBar: some View {
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
    }

    var dismissButton: some View {
        Button {
            viewModel.send(.view(.closeButtonTapped))
        } label: {
            Image(systemName: Constant.dismissImage)
                .font(.system(size: Constant.dismissImageSize, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: Constant.dismissButtonSize, height: Constant.dismissButtonSize)
        }
        .padding(.top, Constant.dismissButtonTopPadding)
    }
    
    var captureAspectRatio: CGFloat {
        let mode = viewModel.state.capturedMedia?.mode ?? viewModel.state.mode

        switch mode {
        case .photo:
            return 3 / 4
        case .video:
            return 9 / 16
        }
    }

}

// MARK: - Constant
private extension CaptureView {
    enum Constant {
        static let dismissImage = "xmark"
        static let dismissImageSize: CGFloat = 18
        static let dismissButtonSize: CGFloat = 52
        static let dismissButtonTopPadding: CGFloat = 0
        static let previewControlSpacing: CGFloat = 16
        static let resultControlSpacing: CGFloat = 16
        static let cameraPermissionAlertTitle = "카메라 권한이 필요합니다"
        static let cameraPermissionAlertMessage = "사진과 영상을 촬영하려면 설정에서 카메라 권한을 허용해 주세요."
        static let cancelTitle = "취소"
        static let openSettingsTitle = "설정으로 이동"
    }
}
