//
//  PlayerLayerView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/22/26.
//

import AVFoundation
import SwiftUI
import UIKit

public struct PlayerLayerView: UIViewRepresentable {
    private let player: AVPlayer
    private let videoGravity: AVLayerVideoGravity

    public init(
        player: AVPlayer,
        videoGravity: AVLayerVideoGravity
    ) {
        self.player = player
        self.videoGravity = videoGravity
    }

    public func makeUIView(context: Context) -> UIView {
        let view = PlayerLayerContainerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = videoGravity
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView as? PlayerLayerContainerView else { return }
        view.playerLayer.player = player
        view.playerLayer.videoGravity = videoGravity
    }
}

private final class PlayerLayerContainerView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}
