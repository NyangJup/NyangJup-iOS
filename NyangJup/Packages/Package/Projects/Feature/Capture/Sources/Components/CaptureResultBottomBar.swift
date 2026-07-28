//
//  CaptureResultBottomBar.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import SwiftUI

import CoreCameraInterface

struct CaptureResultBottomBar: View {
    let mode: CaptureMode
    let capturedMedia: CapturedMedia?
    let trimThumbnails: [UIImage]?
    let trimDuration: Double?
    let trimStartTime: Binding<Double>
    let trimEndTime: Binding<Double>
    let trimCurrentTime: Binding<Double>
    let onRetake: () -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack {
            if let trimThumbnails, let trimDuration {
                VideoTrimBar(
                    thumbnails: trimThumbnails,
                    duration: trimDuration,
                    startTime: trimStartTime,
                    endTime: trimEndTime,
                    currentTime: trimCurrentTime
                )
                .padding(.horizontal, Constant.trimBarHorizontalPadding)
            }

            CapturedBottomBar(
                media: mode == .photo ? Constant.photoMediaName : Constant.videoMediaName,
                capturedMedia: capturedMedia,
                onRetake: onRetake,
                onComplete: { _ in onComplete() }
            )
        }
    }
}

private extension CaptureResultBottomBar {
    enum Constant {
        static let photoMediaName = "사진"
        static let videoMediaName = "영상"
        static let trimBarHorizontalPadding: CGFloat = 12
    }
}
