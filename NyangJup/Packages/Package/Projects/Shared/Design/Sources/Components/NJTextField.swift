//
//  NJTextField.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import SwiftUI

public struct NJTextField: View {
    @Binding private var text: String

    private let placeholder: String
    private let maxLength: Int

    public init(
        text: Binding<String>,
        placeholder: String,
        maxLength: Int
    ) {
        self._text = text
        self.placeholder = placeholder
        self.maxLength = maxLength
    }

    public var body: some View {
        TextField(placeholder, text: $text)
            .font(.system(size: Constant.fontSize, weight: .semibold))
            .padding(.horizontal, Constant.horizontalPadding)
            .frame(height: Constant.height)
            .background(
                .gray.opacity(Constant.backgroundOpacity),
                in: RoundedRectangle(cornerRadius: Constant.cornerRadius)
            )
            .onChange(of: text) { _, newValue in
                if newValue.count > maxLength {
                    text = String(newValue.prefix(maxLength))
                }
            }
            .overlay(alignment: .trailing) {
                Text("\(text.count)/\(maxLength)")
                    .font(.caption)
                    .padding(.trailing, Constant.countTrailingPadding)
            }
    }
}

// MARK: - Constant

private extension NJTextField {
    enum Constant {
        static let fontSize: CGFloat = 17
        static let horizontalPadding: CGFloat = 16
        static let height: CGFloat = 52
        static let cornerRadius: CGFloat = 14
        static let countTrailingPadding: CGFloat = 12
        static let backgroundOpacity: Double = 0.1
    }
}
