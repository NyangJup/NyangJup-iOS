//
//  CapturePreviewView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import SwiftUI

import CoreCameraInterface

struct CapturePreviewView: View {
    let zoomFactor: CGFloat
    let cameraController: any CameraSessionControlling
    let onZoomChanged: (CGFloat) -> Void
    let isRecording: Bool

    @State private var pinchStartZoomFactor: CGFloat?

    var body: some View {
        ZStack {
            CameraPreviewView(controller: cameraController)
                .gesture(zoomGesture)
                .overlay(alignment: .top) {
                    zoomIndicator
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            GeometryReader { geometry in
                if isRecording {
                    recordingTimer(in: geometry.size)
                }
            }
        }
    }
}

private extension CapturePreviewView {
    func recordingTimer(in containerSize: CGSize) -> some View {
        TimelineView(.periodic(from: .now, by: Constant.timerRefreshInterval)) { _ in
            let duration = cameraController.recordedDuration
            let recordedDuration = duration.isFinite ? max(0, duration) : 0
            let remainingDuration = max(0, Constant.maxRecordingDuration - recordedDuration)
            let isCompact = recordedDuration >= Constant.timerCompactDelay

            Text("\(Int(ceil(remainingDuration)))")
                .font(.system(size: Constant.timerFontSize, weight: .bold))
                .foregroundStyle(.white)
                .frame(
                    width: Constant.timerFrameSize.width,
                    height: Constant.timerFrameSize.height
                )
                .shadow(color: .gray.opacity(0.8), radius: 0, x: 1, y: 1)
                .shadow(color: .gray.opacity(0.8), radius: 0, x: -1, y: 1)
                .shadow(color: .gray.opacity(0.8), radius: 0, x: 1, y: -1)
                .shadow(color: .gray.opacity(0.8), radius: 0, x: -1, y: -1)
                .scaleEffect(isCompact ? Constant.compactTimerScale : 1)
                .position(timerPosition(in: containerSize, isCompact: isCompact))
                .animation(
                    .easeInOut(duration: Constant.timerAnimationDuration),
                    value: isCompact
                )
        }
    }

    func timerPosition(in containerSize: CGSize, isCompact: Bool) -> CGPoint {
        guard isCompact else {
            return CGPoint(
                x: containerSize.width / 2,
                y: containerSize.height / 2
            )
        }

        let compactTimerSize = CGSize(
            width: Constant.timerFrameSize.width * Constant.compactTimerScale,
            height: Constant.timerFrameSize.height * Constant.compactTimerScale
        )

        return CGPoint(
            x: Constant.compactTimerHorizontalPadding + compactTimerSize.width / 2,
            y: containerSize.height
                - Constant.compactTimerBottomPadding
                - compactTimerSize.height / 2
        )
    }

    var zoomIndicator: some View {
        Text(String(format: Constant.zoomFormat, zoomFactor))
            .font(.caption)
            .foregroundStyle(.yellow)
            .padding(Constant.zoomIndicatorPadding)
            .background(Circle().fill(.black.opacity(Constant.zoomIndicatorOpacity)))
            .padding(.top, Constant.zoomIndicatorTopPadding)
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
        static let zoomFormat = "%.1fx"
        static let zoomIndicatorPadding: CGFloat = 12
        static let zoomIndicatorTopPadding: CGFloat = 12
        static let zoomIndicatorOpacity: Double = 0.4
        static let maxRecordingDuration: TimeInterval = 60
        
        static let timerCompactDelay: TimeInterval = 1
        static let timerRefreshInterval: TimeInterval = 0.1
        static let timerFontSize: CGFloat = 48
        static let timerFrameSize = CGSize(width: 80, height: 60)
        
        static let compactTimerScale: CGFloat = 0.5
        static let compactTimerHorizontalPadding: CGFloat = 16
        static let compactTimerBottomPadding: CGFloat = 16
        static let timerAnimationDuration: TimeInterval = 0.4
    }
}
