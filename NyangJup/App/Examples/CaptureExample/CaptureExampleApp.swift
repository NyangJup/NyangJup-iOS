//
//  CaptureExampleApp.swift
//  NyangJup
//
//  Created by 정지훈 on 9/11/26.
//

import SwiftUI

import CoreCamera
import CoreCameraInterface
import CoreCameraTesting
import CoreVideoClient
import DomainMediaTesting
import FeatureCapture
import FeatureCaptureInterface

@main
struct CaptureExampleApp: App {
    private let captureFactory: CaptureFactory

    init() {
        let cameraClient = CameraClient.live

        captureFactory = .live(
            cameraClient: cameraClient,
            mediaClient: .test,
            videoTrimClient: .live
        )
    }

    var body: some Scene {
        WindowGroup {
            captureFactory.makeView(
                CaptureConfiguration(
                    usage: .media,
                    showsModePicker: true
                ),
                CaptureDelegate { _ in }
            )
        }
    }
}
