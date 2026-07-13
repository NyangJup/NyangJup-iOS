//
//  CameraControlBar.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import PhotosUI
import SwiftUI

import CoreCameraInterface

struct CameraControlBar: View {
    @Binding var mode: CaptureMode
    let isRecording: Bool?
    let showsModePicker: Bool
    let onPhotoPickerChanged: (PhotosPickerItem?) -> Void
    let onCapture: () -> Void
    let onSwitchCamera: () -> Void

    var body: some View {
        VStack(spacing: Constant.controlSpacing) {
            captureButton

            HStack(spacing: 0) {
                albumButton
                Spacer()
                modePickerArea
                Spacer()
                switchButton
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Constant.horizontalPadding)
        }
    }
}

private extension CameraControlBar {
    var modePicker: some View {
        Picker("", selection: $mode) {
            Text(Constant.photoMediaName).tag(CaptureMode.photo)
            Text(Constant.videoMediaName).tag(CaptureMode.video)
        }
        .pickerStyle(.segmented)
        .tint(.white)
        .colorScheme(.dark)
        .frame(width: Constant.modePickerWidth)
        .opacity(isRecording == true ? 0 : 1)
        .animation(.easeInOut, value: isRecording)
    }

    @ViewBuilder
    var modePickerArea: some View {
        if showsModePicker {
            modePicker
        } else {
            Color.clear.frame(width: Constant.modePickerWidth)
        }
    }

    var albumButton: some View {
        PhotosPicker(
            selection: Binding(
                get: { nil },
                set: { onPhotoPickerChanged($0) }
            ),
            matching: .all(of: [.images, .videos])
        ) {
            Image(systemName: Constant.albumImage)
                .font(.system(size: Constant.secondaryButtonImageSize, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: Constant.secondaryButtonSize, height: Constant.secondaryButtonSize)
                .background(.black.opacity(Constant.albumBackgroundOpacity), in: Circle())
        }
        .glassEffect(.clear.interactive())
        .opacity(isRecording == true ? 0 : 1)
        .animation(.easeInOut, value: isRecording)
    }

    var captureButton: some View {
        Button {
            onCapture()
        } label: {
            Circle()
                .stroke(.white, lineWidth: Constant.captureButtonLineWidth)
                .frame(width: Constant.captureButtonSize, height: Constant.captureButtonSize)
                .overlay {
                    switch mode {
                    case .photo:
                        Circle().fill(.white).frame(width: Constant.captureContentSize, height: Constant.captureContentSize)
                    case .video:
                        if isRecording != nil {
                            Rectangle().fill(.red.opacity(Constant.recordingOpacity)).frame(width: Constant.recordingStopSize, height: Constant.recordingStopSize)
                        } else {
                            Circle().fill(.red.opacity(Constant.recordingOpacity)).frame(width: Constant.captureContentSize, height: Constant.captureContentSize)
                        }
                    }
                }
        }
        .glassEffect(.clear.interactive())
    }

    var switchButton: some View {
        Button {
            onSwitchCamera()
        } label: {
            Image(systemName: Constant.switchCameraImage)
                .font(.system(size: Constant.secondaryButtonImageSize, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: Constant.switchButtonSize, height: Constant.switchButtonSize)
        }
        .glassEffect(.clear.interactive())
    }
}

private extension CameraControlBar {
    enum Constant {
        static let photoMediaName = "사진"
        static let videoMediaName = "영상"
        static let albumImage = "photo.on.rectangle"
        static let switchCameraImage = "arrow.triangle.2.circlepath.camera"

        static let controlSpacing: CGFloat = 20
        static let horizontalPadding: CGFloat = 28
        static let modePickerWidth: CGFloat = 150
        static let secondaryButtonImageSize: CGFloat = 20
        static let secondaryButtonSize: CGFloat = 52
        static let switchButtonSize: CGFloat = 44
        static let albumBackgroundOpacity: Double = 0.45
        static let captureButtonSize: CGFloat = 74
        static let captureButtonLineWidth: CGFloat = 1
        static let captureContentSize: CGFloat = 64
        static let recordingStopSize: CGFloat = 30
        static let recordingOpacity: Double = 0.9
    }
}
