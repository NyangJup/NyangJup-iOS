//
//  CapturedVideoView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/27/26.
//

import AVKit
import SwiftUI

struct CapturedVideoView: View {
    @Binding var trimStartTime: Double?
    @Binding var trimEndTime: Double?
    @Binding var currentTime: Double?

    @State private var player: AVPlayer

    init(
        url: URL,
        trimStartTime: Binding<Double?>,
        trimEndTime: Binding<Double?>,
        currentTime: Binding<Double?>
    ) {
        self._trimStartTime = trimStartTime
        self._trimEndTime = trimEndTime
        self._currentTime = currentTime
        self._player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        VideoPlayer(
            player: player,
            startTime: $trimStartTime,
            endTime: $trimEndTime,
            currentTime: $currentTime
        )
        .contentShape(.rect)
    }
}
