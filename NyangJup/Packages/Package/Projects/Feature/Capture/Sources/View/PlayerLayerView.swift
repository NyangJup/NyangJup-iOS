//
//  PlayerLayerView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import UIKit
import SwiftUI
import AVKit

struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerLayerContainerView {
        let view = PlayerLayerContainerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PlayerLayerContainerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

final class PlayerLayerContainerView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}
