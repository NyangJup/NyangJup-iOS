//
//  CatSubmitButton.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import SwiftUI

struct CatSubmitButton: View {
    @Binding var name: String
    let onSubmit: () -> Void

    var body: some View {
        Button(action: onSubmit) {
            Text(Constant.title)
                .font(.system(size: Constant.fontSize, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Constant.height)
        }
        .background(
            name.isEmpty
                ? .gray.opacity(Constant.disabledOpacity)
                : .red.opacity(Constant.enabledOpacity),
            in: RoundedRectangle(cornerRadius: Constant.cornerRadius)
        )
        .disabled(name.isEmpty)
    }
}

// MARK: - Constant

private extension CatSubmitButton {
    enum Constant {
        static let title = "확인"
        static let fontSize: CGFloat = 18
        static let height: CGFloat = 56
        static let cornerRadius: CGFloat = 16
        static let disabledOpacity: Double = 0.5
        static let enabledOpacity: Double = 0.7
    }
}
