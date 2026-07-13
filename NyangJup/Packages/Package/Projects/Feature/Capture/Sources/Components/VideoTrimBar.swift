//
//  VideoTrimBar.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import Foundation

import SwiftUI


struct VideoTrimBar: View {
    let thumbnails: [UIImage]
    let duration: Double
    
    @State private var leftDragStartTime: Double?
    @State private var rightDragEndTime: Double?
    @State private var currentDragTime: Double?
    
    @Binding var startTime: Double
    @Binding var endTime: Double
    @Binding var currentTime: Double

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let trackX = Constant.handleWidth
            let trackWidth = max(0, width - Constant.handleWidth * 2)
            
            let startX = trackX + xPosition(for: startTime, width: trackWidth)
            let endX = trackX + xPosition(for: endTime, width: trackWidth)
            let currentTimeX = trackX + xPosition(for: currentTime, width: trackWidth)

            ZStack(alignment: .leading) {
                thumbnailStrip(width: trackWidth)
                    .frame(width: trackWidth)
                    .offset(x: trackX)
                    .contentShape(.rect)

                Rectangle()
                    .fill(.black.opacity(0.45))
                    .frame(width: max(0, startX - trackX))
                    .offset(x: trackX)
                    .allowsHitTesting(false)

                Rectangle()
                    .fill(.black.opacity(0.45))
                    .frame(width: max(0, trackX + trackWidth - endX))
                    .offset(x: endX)
                    .allowsHitTesting(false)

                currentTimeHandle
                    .offset(x: currentTimeX - Constant.currentTimeTouchWidth / 2)
                    .highPriorityGesture(currentTimeGesture(width: trackWidth))
                    
                handle(radius: .init(topLeading: 3, bottomLeading: 3))
                    .offset(x: startX - Constant.handleWidth)
                    .highPriorityGesture(leftHandleGesture(width: trackWidth))

                handle(radius: .init(bottomTrailing: 3, topTrailing: 3))
                    .offset(x: endX)
                    .highPriorityGesture(rightHandleGesture(width: trackWidth))
            }
            .frame(width: width, height: Constant.barHeight, alignment: .leading)
        }
        .frame(height: Constant.barHeight)
    }

    private var currentTimeHandle: some View {
        Color.clear
            .frame(width: Constant.currentTimeTouchWidth, height: Constant.barHeight)
            .contentShape(.rect)
            .overlay {
                Rectangle()
                    .fill(.white)
                    .frame(width: Constant.currentTimeLineWidth, height: Constant.barHeight)
            }
    }

    @ViewBuilder
    private func thumbnailStrip(width: CGFloat) -> some View {
        let thumbnailWidth = thumbnails.isEmpty ? 0 : width / CGFloat(thumbnails.count)

        HStack(spacing: 0) {
            ForEach(Array(thumbnails.enumerated()), id: \.offset) { _, image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: thumbnailWidth, height: Constant.barHeight)
                    .clipped()
            }
        }
        .frame(width: width, height: Constant.barHeight)
    }

    private func handle(radius: RectangleCornerRadii) -> some View {
        UnevenRoundedRectangle(cornerRadii: radius)
            .fill(Constant.handleColor)
            .frame(width: Constant.handleWidth, height: Constant.barHeight)
            .contentShape(.rect)
    }
}

private extension VideoTrimBar {
    func xPosition(for time: Double, width: CGFloat) -> CGFloat {
        guard duration > 0 else { return 0 }
        return CGFloat(time / duration) * width
    }

    func clampedTime(time: Double, min minTime: Double, max maxTime: Double) -> Double {
        min(max(time, minTime), maxTime)
    }
    
}

private extension VideoTrimBar {
    func currentTimeGesture(width: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard width > 0 else { return }
                let dragStartTime = currentDragTime ?? currentTime
                
                currentDragTime = dragStartTime
                let timeDelta = Double(value.translation.width / width) * duration
                let newTime = clampedTime(
                    time: dragStartTime + timeDelta,
                    min: startTime,
                    max: endTime
                )
                currentTime = newTime
            }
            .onEnded { _ in
                currentDragTime = nil
            }
    }

    func updateStartTime(_ newStart: Double) {
        startTime = clampedTime(
            time: newStart,
            min: max(0, endTime - Constant.maxDuration),
            max: endTime
        )
        if currentTime < startTime { currentTime = startTime }
    }

    func updateEndTime(_ newEnd: Double) {
        endTime = clampedTime(
            time: newEnd,
            min: startTime,
            max: min(duration, startTime + Constant.maxDuration)
        )
        
        if endTime < currentTime { currentTime = endTime }
    }

    func leftHandleGesture(width: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard width > 0 else { return }
                let dragStartTime = leftDragStartTime ?? startTime
                leftDragStartTime = dragStartTime
                let timeDelta = Double(value.translation.width / width) * duration
                updateStartTime(dragStartTime + timeDelta)
            }
            .onEnded { _ in
                leftDragStartTime = nil
            }
    }

    func rightHandleGesture(width: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard width > 0 else { return }
                let dragStartTime = rightDragEndTime ?? endTime
                rightDragEndTime = dragStartTime
                let timeDelta = Double(value.translation.width / width) * duration
                updateEndTime(dragStartTime + timeDelta)
            }
            .onEnded { _ in
                rightDragEndTime = nil
            }
    }
}

private extension VideoTrimBar {
    enum Constant {
        static let maxDuration: Double = 60
        static let barHeight: CGFloat = 64
        static let handleWidth: CGFloat = 14
        static let currentTimeTouchWidth: CGFloat = 24
        static let currentTimeLineWidth: CGFloat = 2
        static let handleColor: Color = .yellow
    }
}
