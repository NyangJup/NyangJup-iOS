import SwiftUI

import SharedDesign

public struct NyangJupSplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startedAt = Date.now
    @Binding var showSplash: Bool

    public init(showSplash: Binding<Bool>) {
        self._showSplash = showSplash
    }

    public var body: some View {
        TimelineView(.animation) { context in
            let time = max(0, context.date.timeIntervalSince(startedAt))
            GeometryReader { proxy in
                let scale = min(
                    1,
                    min(
                        proxy.size.width / Constant.minimumLayoutWidth,
                        proxy.size.height / Constant.minimumLayoutHeight
                    )
                )
                composition(time: time)
                    .scaleEffect(scale)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("냥줍")
        .task {
            do {
                try await Task.sleep(for: Constant.displayDuration)
                withAnimation(.easeOut(duration: Constant.dismissDuration)) {
                    showSplash = false
                }
            } catch { }
        }
    }

    private func progress(_ time: Double, from start: Double, duration: Double) -> Double {
        let value = min(1, max(0, (time - start) / duration))
        return value * value * (3 - 2 * value)
    }

    private func composition(time: Double) -> some View {
        let cat = progress(time, from: 0, duration: 0.65)
        let phone = progress(time, from: 0.7, duration: 0.65)
        let pixel = progress(time, from: 1.4, duration: 0.28)
        let title = progress(time, from: 1.8, duration: 0.55)
        let ink = Color(red: 0.29, green: 0.16, blue: 0.10)

        return VStack(spacing: Constant.titleSpacing) {
            ZStack {
                ZStack {
                    NJImage.splashCat.image
                        .resizable()
                        .frame(
                            width: Constant.illustratedCatSize.width,
                            height: Constant.illustratedCatSize.height
                        )
                        .opacity(1 - pixel)
                    
                    NJImage.splashPixelCat.image
                        .resizable()
                        .interpolation(.none)
                        .frame(
                            width: Constant.pixelCatSize.width,
                            height: Constant.pixelCatSize.height
                        )
                        .opacity(pixel)
                }
                .opacity(cat)
                .scaleEffect(reduceMotion ? 1 : 0.9 + 0.1 * cat)
                .offset(
                    y: Constant.catVerticalOffset +
                    (reduceMotion ? 0 : 12 * (1 - cat))
                )
                
                NJImage.iPhoneFrame.image
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: Constant.phoneSize.width,
                        height: Constant.phoneSize.height
                    )
                    .opacity(phone)
                
                Circle()
                    .stroke(.black, lineWidth: 4)
                    .fill(.white)
                    .frame(
                        width: Constant.captureButtonInnerSize,
                        height: Constant.captureButtonInnerSize
                    )
                    .offset(y: Constant.captureButtonVerticalOffset)
                    .opacity(phone)

                ZStack {
                    focusCorners
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(
                            width: Constant.focusSize.width,
                            height: Constant.focusSize.height
                        )
                        .scaleEffect(reduceMotion ? 1 : 1.12 - 0.12 * phone)
                        .opacity(1 - pixel)
                }
                .frame(
                    width: Constant.phoneSize.width,
                    height: Constant.phoneSize.height
                )
                .opacity(phone)
                .offset(y: reduceMotion ? 0 : 50 * (1 - phone))
                .rotationEffect(.degrees(reduceMotion ? 0 : -7 * (1 - phone)))

                RoundedRectangle(cornerRadius: 26)
                    .fill(.white)
                    .frame(
                        width: Constant.screenSize.width,
                        height: Constant.screenSize.height
                    )
                    .opacity(reduceMotion ? 0 : max(0, 1 - abs(time - 1.45) / 0.10) * 0.65)
            }
            .frame(
                width: Constant.artworkSize.width,
                height: Constant.artworkSize.height
            )

            Text("냥줍")
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .tracking(4)
                .foregroundStyle(ink)
                .opacity(title)
                .scaleEffect(reduceMotion ? 1 : 0.88 + 0.12 * title + sin(title * .pi) * 0.08)
                .offset(y: reduceMotion ? 0 : 12 * (1 - title))
        }
    }

    private var focusCorners: Path {
        Path { path in
            let width = Constant.focusSize.width
            let height = Constant.focusSize.height
            let length = Constant.focusCornerLength
            for (x, y, dx, dy) in [(0.0, 0.0, 1.0, 1.0), (width, 0, -1, 1),
                                    (0, height, 1, -1), (width, height, -1, -1)] {
                path.move(to: CGPoint(x: x, y: y + length * dy))
                path.addLine(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x + length * dx, y: y))
            }
        }
    }
}

private extension NyangJupSplashView {
    enum Constant {
        static let minimumLayoutWidth: CGFloat = 320
        static let minimumLayoutHeight: CGFloat = 620

        static let artworkSize = CGSize(width: 250, height: 416)
        static let phoneSize = CGSize(width: 200, height: 416)
        static let screenSize = CGSize(width: 182, height: 382)
        static let focusSize = CGSize(width: 154, height: 214)
        static let illustratedCatSize = CGSize(width: 150, height: 150)
        static let pixelCatSize = CGSize(width: 180, height: 170)

        static let catVerticalOffset: CGFloat = -4
        static let captureButtonSize: CGFloat = 38
        static let captureButtonInnerSize: CGFloat = 30
        static let captureButtonVerticalOffset: CGFloat = 166
        static let focusCornerLength: CGFloat = 16
        static let titleSpacing: CGFloat = 30

        static let displayDuration = Duration.milliseconds(3300)
        static let dismissDuration: TimeInterval = 0.3
    }
}

#Preview {
    NyangJupSplashView(showSplash: .constant(true))
}
