//
//  VideoSeekBar.swift
//  NJPackage
//
//  Created by 정지훈 on 7/23/26.
//

import SwiftUI

struct VideoSeekBar: View {
    let progress: Double
    let onSeek: (Double, Bool) -> Void
    let onSeekingChanged: (Bool) -> Void

    @State private var draggingProgress: Double?
    @State private var lastSeekTimestamp: TimeInterval = 0

    var body: some View {
        GeometryReader { proxy in
            progressBar(width: proxy.size.width)
                .gesture(seekGesture(width: proxy.size.width))
        }
        .frame(height: Constant.touchHeight)
    }

    private func progressBar(width: CGFloat) -> some View {
        let displayedProgress = draggingProgress ?? progress

        return ZStack(alignment: .leading) {
            Capsule()
                .fill(.gray)

            Capsule()
                .fill(.white)
                .frame(width: width * displayedProgress)
        }
        .frame(height: Constant.barHeight)
        .contentShape(.rect)
    }
}

private extension VideoSeekBar {
    func seekGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let progress = normalizedProgress(
                    at: value.location.x,
                    width: width
                )

                if draggingProgress == nil {
                    onSeekingChanged(true)
                }

                draggingProgress = progress

                let timestamp = Date.timeIntervalSinceReferenceDate
                guard
                    timestamp - lastSeekTimestamp
                        >= Constant.seekThrottleInterval
                else { return }

                lastSeekTimestamp = timestamp
                onSeek(progress, false)
            }
            .onEnded { value in
                let progress = normalizedProgress(
                    at: value.location.x,
                    width: width
                )

                draggingProgress = nil
                lastSeekTimestamp = 0
                onSeek(progress, true)
                onSeekingChanged(false)
            }
    }

    func normalizedProgress(
        at location: CGFloat,
        width: CGFloat
    ) -> Double {
        guard width > 0 else { return 0 }

        return Double(min(max(location / width, 0), 1))
    }
}

private extension VideoSeekBar {
    enum Constant {
        static let barHeight: CGFloat = 3
        static let touchHeight: CGFloat = 24
        static let seekThrottleInterval: TimeInterval = 0.05
    }
}
