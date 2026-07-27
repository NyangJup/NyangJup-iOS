//
//  CaptureFactory+Live.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import SwiftUI

import CoreCameraInterface
import FeatureCaptureInterface

public extension CaptureFactory {
    static func live(
        cameraClient: CameraClient
    ) -> Self {
        Self(
            makeView: {
                configuration,
                delegate in
                let configuration = configuration as? CaptureConfiguration
                let delegate = delegate as? CaptureDelegate
                let onAction: @MainActor @Sendable (CaptureDelegate.Action) -> Void = { action in
                    delegate?.send(action)
                }
                
                return AnyView(
                    CaptureView(
                        viewModel: CaptureViewModel(
                            cameraClient: cameraClient,
                            videoTrimClient: VideoTrimClient(),
                            configuration: configuration ?? .init(showsModePicker: true),
                            onComplete: { media in
                                onAction(.complete(media))
                            },
                            onClose: {
                                onAction(.close)
                            }
                        )
                    )
                )
            }
        )
    }
}
