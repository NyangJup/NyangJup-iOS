//
//  CaptureConfirmView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/27/26.
//

import SwiftUI

import SharedDesign

struct CaptureConfirmView: View {
    @Binding private var comment: String
    private let onComplete: () -> Void

    init(
        comment: Binding<String>,
        onComplete: @escaping () -> Void
    ) {
        self._comment = comment
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constant.contentSpacing) {
            Text(Constant.title)
                .font(.system(size: Constant.titleFontSize, weight: .bold))

            NJTextField(
                text: $comment,
                placeholder: Constant.textPlaceholder,
                maxLength: Constant.textMaxLength
            )

            NJButton(
                text: Constant.submitButtonText,
                backgroundColor: .red.opacity(Constant.submitButtonOpacity),
                foregroundColor: .white,
                isEnabled: !comment.isEmpty,
                onTap: onComplete
            )
        }
        .padding(.horizontal, Constant.horizontalPadding)
        .padding(.top, Constant.topPadding)
        .presentationBackground(.white)
        .presentationDetents([.height(Constant.sheetHeight)])
        .presentationCornerRadius(Constant.cornerRadius)
    }
}

// MARK: - Constant

private extension CaptureConfirmView {
    enum Constant {
        static let title = "코멘트를 남겨주세요!"
        static let textPlaceholder = "코멘트"
        static let submitButtonText = "확인"

        static let textMaxLength = 10
        static let titleFontSize: CGFloat = 24
        static let contentSpacing: CGFloat = 20
        static let horizontalPadding: CGFloat = 20
        static let topPadding: CGFloat = 16
        static let sheetHeight: CGFloat = 220
        static let cornerRadius: CGFloat = 28
        static let submitButtonOpacity: Double = 0.7
    }
}
