//
//  VideoPlayer.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import AVKit
import SwiftUI

public struct VideoPlayer: View {
    private let player: AVPlayer

    @State private var videoTimeObserver: Any?
    @State private var playbackTime: Double?
    @Binding private var startTime: Double?
    @Binding private var endTime: Double?
    @Binding private var currentTime: Double?
    
    public init(
        player: AVPlayer,
        startTime: Binding<Double?>,
        endTime: Binding<Double?>,
        currentTime: Binding<Double?>
    ) {
        self.player = player
        self._startTime = startTime
        self._endTime = endTime
        self._currentTime = currentTime
    }
    
    public var body: some View {
        PlayerLayerView(player: player)
            .onTapGesture {
                toggleVideoPlayback()
            }
            .onAppear {
                addVideoTimeObserver()
            }
            .onChange(of: currentTime) {
                guard currentTime != playbackTime else { return }
                seekVideo(to: currentTime)
            }
            .onDisappear {
                removeVideoTimeObserver()
            }
    }
}


private extension VideoPlayer {
    func toggleVideoPlayback() {
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
    }
    
    func addVideoTimeObserver() {
        videoTimeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: Constant.observerInterval, preferredTimescale: Constant.timeScale),
            queue: .main
        ) { time in
            MainActor.assumeIsolated {
                guard let startTime, let endTime else { return }

                let seconds = time.seconds

                if seconds > endTime {
                    updateCurrentTime(endTime)
                    player.pause()
                } else if seconds < startTime {
                    updateCurrentTime(startTime)
                } else {
                    updateCurrentTime(seconds)
                }
            }
        }
    }
    
    func removeVideoTimeObserver() {
        guard let videoTimeObserver else { return }
        
        player.removeTimeObserver(videoTimeObserver)
        self.videoTimeObserver = nil
    }
    
    func seekVideo(to seconds: Double?) {
        guard let seconds else { return }
        let time = CMTime(seconds: seconds, preferredTimescale: Constant.timeScale)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func updateCurrentTime(_ time: Double) {
        playbackTime = time
        currentTime = time
    }
}

private extension VideoPlayer {
    enum Constant {
        static let observerInterval: Double = 0.05
        static let timeScale: CMTimeScale = 600
    }
}
