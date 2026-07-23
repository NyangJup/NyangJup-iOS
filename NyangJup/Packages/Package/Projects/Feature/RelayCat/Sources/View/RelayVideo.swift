//
//  RelayVideo.swift
//  NJPackage
//
//  Created by 정지훈 on 7/23/26.
//

import AVKit
import SwiftUI

import CoreVideoInterface

struct RelayVideo: View {
    @State private var player: AVPlayer
    @State private var playbackProgress: Double = 0
    @State private var timeObserverToken: Any?
    @State private var shouldPlay = true

    let isActive: Bool

    init(url: URL, isActive: Bool) {
        self._player = State(initialValue: AVPlayer(url: url))
        self.isActive = isActive
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            videoContent

            Spacer()

            seekBar
        }
        .onChange(of: isActive, initial: true) { _, isActive in
            handleActiveState(isActive)
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: AVPlayerItem.didPlayToEndTimeNotification,
                object: player.currentItem
            )
        ) { _ in
            handlePlaybackEnded()
        }
        .onDisappear(perform: stopProgressObservation)
    }

    private var videoContent: some View {
        PlayerLayerView(
            player: player,
            videoGravity: .resizeAspect
        )
        .contentShape(.rect)
        .onTapGesture(perform: togglePlayback)
    }

    private var seekBar: some View {
        VideoSeekBar(
            progress: playbackProgress,
            onSeek: seek,
            onSeekingChanged: handleSeekingChanged
        )
        .padding(.horizontal, Constant.seekBarHorizontalPadding)
        .padding(.bottom, Constant.seekBarBottomPadding)
    }
}

private extension RelayVideo {
    func handleActiveState(_ isActive: Bool) {
        if isActive, shouldPlay {
            startProgressObservation()
            player.play()
        } else {
            stopProgressObservation()
            shouldPlay = true
            player.pause()
            player.seek(to: .zero)
            playbackProgress = 0
        }
    }

    func togglePlayback() {
        guard isActive else { return }

        shouldPlay.toggle()

        if shouldPlay {
            player.play()
        } else {
            player.pause()
        }
    }

    func seek(to progress: Double, isFinal: Bool) {
        guard
            let duration = player.currentItem?.duration.seconds,
            duration.isFinite,
            duration > 0
        else { return }

        playbackProgress = progress
        let tolerance = isFinal
            ? CMTime.zero
            : CMTime(
                seconds: Constant.seekTolerance,
                preferredTimescale: Constant.timeScale
            )

        player.seek(
            to: CMTime(
                seconds: duration * progress,
                preferredTimescale: Constant.timeScale
            ),
            toleranceBefore: tolerance,
            toleranceAfter: tolerance
        )
    }

    func handleSeekingChanged(_ isSeeking: Bool) {
        if isSeeking {
            player.pause()
        } else if isActive, shouldPlay {
            player.play()
        }
    }

    func handlePlaybackEnded() {
        playbackProgress = 0
        player.seek(to: .zero)

        if isActive, shouldPlay {
            player.play()
        }
    }

    func startProgressObservation() {
        guard timeObserverToken == nil else { return }

        let player = player
        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(
                seconds: Constant.observerInterval,
                preferredTimescale: Constant.timeScale
            ),
            queue: .main
        ) { time in
            Task { @MainActor in
                guard
                    let duration = player.currentItem?.duration.seconds,
                    duration.isFinite,
                    duration > 0,
                    time.seconds.isFinite
                else {
                    playbackProgress = 0
                    return
                }

                playbackProgress = min(
                    max(time.seconds / duration, 0),
                    1
                )
            }
        }
    }

    func stopProgressObservation() {
        guard let timeObserverToken else { return }

        player.removeTimeObserver(timeObserverToken)
        self.timeObserverToken = nil
    }
}

private extension RelayVideo {
    enum Constant {
        static let seekBarHorizontalPadding: CGFloat = 16
        static let seekBarBottomPadding: CGFloat = 8
        static let seekTolerance: Double = 0.25
        static let observerInterval: Double = 0.1
        static let timeScale: CMTimeScale = 600
    }
}
