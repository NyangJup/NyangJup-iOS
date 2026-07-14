//
//  CameraPreview.swift
//  NJPackage
//
//  Created by 정지훈 on 7/7/26.
//

import AVFoundation
import SwiftUI
import UIKit


import CoreCameraInterface

struct CameraPreviewView: UIViewRepresentable {
    let controller: any CameraSessionControlling

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = controller.session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = controller.session
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
