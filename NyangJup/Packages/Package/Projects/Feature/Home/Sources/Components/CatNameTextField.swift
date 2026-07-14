//
//  CatNameTextField.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import SwiftUI

struct CatNameTextField: View {
    @Binding var name: String

    var body: some View {
        TextField(Constant.placeholder, text: $name)
            .font(.system(size: Constant.fontSize, weight: .semibold))
            .padding(.horizontal, Constant.horizontalPadding)
            .frame(height: Constant.height)
            .background(
                .gray.opacity(Constant.backgroundOpacity),
                in: RoundedRectangle(cornerRadius: Constant.cornerRadius)
            )
            .onChange(of: name) { _, newValue in
                if newValue.count > Constant.maxCount {
                    name = String(newValue.prefix(Constant.maxCount))
                }
            }
            .overlay(alignment: .trailing) {
                Text("\(name.count)/\(Constant.maxCount)")
                    .font(.caption)
                    .padding(.trailing, Constant.countTrailingPadding)
            }
    }
}

// MARK: - Constant

private extension CatNameTextField {
    enum Constant {
        static let placeholder = "이름"
        static let maxCount = 5
        static let fontSize: CGFloat = 17
        static let horizontalPadding: CGFloat = 16
        static let height: CGFloat = 52
        static let cornerRadius: CGFloat = 14
        static let countTrailingPadding: CGFloat = 12
        static let backgroundOpacity: Double = 0.1
    }
}
