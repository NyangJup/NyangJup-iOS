//
//  CaptureFactory+Live.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import SwiftUI

import CoreCameraInterface
import CoreVideoInterface
import DomainMediaInterface
import FeatureCaptureInterface

public extension CaptureFactory {
    static func live(
        cameraClient: CameraClient,
        mediaClient: MediaClient,
        videoTrimClient: VideoTrimClient
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
                            mediaClient: mediaClient,
                            videoTrimClient: videoTrimClient,
                            configuration: configuration ?? .init(
                                showsModePicker: true,
                                cat: nil
                            ),
                            onUpload: { request in
                                onAction(.upload(request))
                            },
                            onComplete: { capturedMedia, uploadedMedia in
                                if let uploadedMedia {
                                    onAction(.complete(uploadedMedia))
                                } else {
                                    onAction(.register(capturedMedia))
                                }
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
