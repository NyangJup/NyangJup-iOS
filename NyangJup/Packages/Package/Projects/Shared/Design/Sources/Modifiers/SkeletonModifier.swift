//
//  SkeletonModifier.swift
//  NJPackage
//

import SwiftUI

public extension View {
    @ViewBuilder
    func skeleton(isActive: Bool = true) -> some View {
        if isActive {
            modifier(SkeletonModifier())
        } else {
            self
        }
    }
}

private struct SkeletonModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @State private var isPulseHighlighted: Bool = false

    func body(content: Content) -> some View {
        content
            .hidden()
            .overlay {
                pulseColor
            }
            .mask {
                content
            }
            .task(id: accessibilityReduceMotion) {
                await animatePulse()
            }
    }
}

private extension SkeletonModifier {
    var pulseColor: Color {
        Color.secondary.opacity(
            isPulseHighlighted && !accessibilityReduceMotion
                ? highlightedOpacity
                : baseOpacity
        )
    }

    var baseOpacity: Double {
        colorScheme == .dark
            ? Constant.darkBaseOpacity
            : Constant.lightBaseOpacity
    }

    var highlightedOpacity: Double {
        colorScheme == .dark
            ? Constant.darkHighlightedOpacity
            : Constant.lightHighlightedOpacity
    }

    func animatePulse() async {
        isPulseHighlighted = false
        guard !accessibilityReduceMotion else { return }

        while !Task.isCancelled {
            withAnimation(.easeInOut(duration: Constant.animationDuration)) {
                isPulseHighlighted.toggle()
            }

            try? await Task.sleep(for: .seconds(Constant.animationDuration))
        }
    }

    enum Constant {
        static let lightBaseOpacity: Double = 0.12
        static let darkBaseOpacity: Double = 0.18
        static let lightHighlightedOpacity: Double = 0.27
        static let darkHighlightedOpacity: Double = 0.34
        static let animationDuration: TimeInterval = 0.9
    }
}
