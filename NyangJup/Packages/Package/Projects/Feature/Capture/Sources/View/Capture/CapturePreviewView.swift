//
//  CapturePreviewView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import AVKit
import SwiftUI

import CoreCameraInterface

struct CapturePreviewView: View {
    let previewImageData: Data?
    let capturedMediaURL: URL?
    let hasResultMedia: Bool
    let isRecording: Bool?
    let zoomFactor: CGFloat
    
    @Binding var trimStartTime: Double?
    @Binding var trimEndTime: Double?
    @Binding var currentTime: Double?
    
    let cameraController: any CameraSessionControlling
    let onZoomChanged: (CGFloat) -> Void

    @State private var pinchStartZoomFactor: CGFloat?
    @State private var videoPlayer: AVPlayer?

    var body: some View {
        preview
            .overlay(alignment: .bottom) {
                if !hasResultMedia {
                    zoomIndicator
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, Constant.topPadding)
            .onChange(of: capturedMediaURL) { _, url in
                videoPlayer = url.map(AVPlayer.init)
            }
    }
}

private extension CapturePreviewView {
    @ViewBuilder
    var preview: some View {
        if let data = previewImageData,
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .background(.black)
        } else if isRecording == false,
                  let videoPlayer {
            VideoPlayer(
                player: videoPlayer,
                startTime: $trimStartTime,
                endTime: $trimEndTime,
                currentTime: $currentTime
            )
            .scaledToFill()
            .contentShape(.rect)
        } else {
            CameraPreviewView(controller: cameraController)
                .gesture(zoomGesture)
        }
    }

    var zoomIndicator: some View {
        Text(String(format: Constant.zoomFormat, zoomFactor))
            .font(.caption)
            .foregroundStyle(.yellow)
            .padding(Constant.zoomIndicatorPadding)
            .background(Circle().fill(.black.opacity(Constant.zoomIndicatorOpacity)))
            .padding(.bottom, Constant.zoomIndicatorBottomPadding)
    }

    var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let startZoomFactor = pinchStartZoomFactor ?? zoomFactor
                pinchStartZoomFactor = startZoomFactor
                onZoomChanged(value.magnification * startZoomFactor)
            }
            .onEnded { _ in
                pinchStartZoomFactor = nil
            }
    }
}

private extension CapturePreviewView {
    enum Constant {
        static let topPadding: CGFloat = 100
        static let zoomFormat = "%.1fx"
        static let zoomIndicatorPadding: CGFloat = 12
        static let zoomIndicatorBottomPadding: CGFloat = 12
        static let zoomIndicatorOpacity: Double = 0.4
    }
}
