//
//  CaptureResultView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/27/26.
//

import SwiftUI

import CoreCameraInterface

struct CaptureResultView: View {
    let media: CapturedMedia

    @Binding var trimStartTime: Double?
    @Binding var trimEndTime: Double?
    @Binding var currentTime: Double?

    @ViewBuilder
    var body: some View {
        switch media.mode {
        case .photo:
            if let data = media.data {
                CapturedPhotoView(data: data)
            }

        case .video:
            if let url = media.url {
                CapturedVideoView(
                    url: url,
                    trimStartTime: $trimStartTime,
                    trimEndTime: $trimEndTime,
                    currentTime: $currentTime
                )
                .id(url)
            }
        }
    }
}
