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

    @State private var pinchStartZoomFactor: CGFloat?

    var body: some View {
        CameraPreviewView(controller: cameraController)
            .gesture(zoomGesture)
            .overlay(alignment: .top) {
                zoomIndicator
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private extension CapturePreviewView {
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
    }
}
