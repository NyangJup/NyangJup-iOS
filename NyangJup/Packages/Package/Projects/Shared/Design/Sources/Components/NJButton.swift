//
//  NJButton.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import SwiftUI

public struct NJButton: View {
    private let text: String
    private let backgroundColor: Color
    private let foregroundColor: Color
    private let isEnabled: Bool
    private let onTap: () -> Void

    public init(
        text: String,
        backgroundColor: Color,
        foregroundColor: Color,
        isEnabled: Bool,
        onTap: @escaping () -> Void
    ) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.isEnabled = isEnabled
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.system(size: Constant.fontSize, weight: .bold))
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: Constant.height)
        }
        .background(
            isEnabled
                ? backgroundColor
                : .gray.opacity(Constant.disabledOpacity),
            in: RoundedRectangle(cornerRadius: Constant.cornerRadius)
        )
        .disabled(!isEnabled)
    }
}

// MARK: - Constant

private extension NJButton {
    enum Constant {
        static let fontSize: CGFloat = 18
        static let height: CGFloat = 56
        static let cornerRadius: CGFloat = 16
        static let disabledOpacity: Double = 0.5
    }
}
