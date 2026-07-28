//
//  LoadingOverlayModifier.swift
//  NJPackage
//
//  Created by 정지훈 on 7/28/26.
//

import SwiftUI

public extension View {
    func loadingOverlay(isPresented: Bool) -> some View {
        modifier(LoadingOverlayModifier(isPresented: isPresented))
    }
}

private struct LoadingOverlayModifier: ViewModifier {
    let isPresented: Bool

    func body(content: Content) -> some View {
        content
            .disabled(isPresented)
            .overlay {
                if isPresented {
                    ZStack {
                        Color.black.opacity(Constant.dimOpacity)
                            .ignoresSafeArea()

                        ProgressView()
                            .controlSize(.large)
                            .tint(.white)
                    }
                    .contentShape(.rect)
                }
            }
    }
}

private extension LoadingOverlayModifier {
    enum Constant {
        static let dimOpacity: Double = 0.45
    }
}
