//
//  CameraPreviewView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/22/26.
//

import AVFoundation
import SwiftUI
import UIKit

public struct CameraPreviewView: UIViewRepresentable {
    private let controller: any CameraSessionControlling

    public init(controller: any CameraSessionControlling) {
        self.controller = controller
    }

    public func makeUIView(context: Context) -> UIView {
        let view = CameraPreviewContainerView()
        view.previewLayer.session = controller.session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView as? CameraPreviewContainerView else { return }
        view.previewLayer.session = controller.session
    }
}

private final class CameraPreviewContainerView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
