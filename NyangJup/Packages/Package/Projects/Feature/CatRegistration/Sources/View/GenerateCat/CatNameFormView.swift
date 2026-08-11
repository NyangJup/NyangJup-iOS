//
//  CatNameFormView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import SwiftUI

import SharedDesign

struct CatNameFormView: View {
    @Binding var name: String
    @Binding var place: String

    let isSubmitEnabled: Bool
    let onSubmit: () -> Void

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Constant.contentSpacing
        ) {
            title

            NJTextField(
                text: $name,
                placeholder: Constant.namePlaceholder,
                maxLength: Constant.nameMaxLength
            )

            NJTextField(
                text: $place,
                placeholder: Constant.placePlaceholder,
                maxLength: Constant.placeMaxLength
            )

            NJButton(
                text: Constant.submitButtonText,
                backgroundColor: .red.opacity(
                    Constant.submitButtonOpacity
                ),
                foregroundColor: .white,
                isEnabled: isSubmitEnabled,
                onTap: onSubmit
            )
        }
        .padding(
            .horizontal,
            Constant.horizontalPadding
        )
        .padding(
            .top,
            Constant.formTopPadding
        )
        .padding(
            .bottom,
            Constant.formBottomPadding
        )
        .frame(maxWidth: .infinity)
        .background(formBackground)
    }
}

// MARK: - View

private extension CatNameFormView {
    var title: some View {
        Text(Constant.title)
            .font(
                .system(
                    size: Constant.titleFontSize,
                    weight: .bold
                )
            )
    }

    var formBackground: some View {
        UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: Constant.formCornerRadius,
                topTrailing: Constant.formCornerRadius
            )
        )
        .fill(.white)
        .shadow(
            color: .black.opacity(
                Constant.shadowOpacity
            ),
            radius: Constant.shadowRadius,
            y: Constant.shadowYOffset
        )
    }
}

// MARK: - Constant

private extension CatNameFormView {
    enum Constant {
        static let title = "냥이 소개"
        static let namePlaceholder = "이름"
        static let nameMaxLength = 5
        static let placePlaceholder = "장소"
        static let placeMaxLength = 20
        static let submitButtonText = "확인"

        static let submitButtonOpacity: Double = 0.7
        static let titleFontSize: CGFloat = 24
        static let contentSpacing: CGFloat = 20
        static let horizontalPadding: CGFloat = 20
        static let formTopPadding: CGFloat = 24
        static let formBottomPadding: CGFloat = 16
        static let formCornerRadius: CGFloat = 28
        static let shadowRadius: CGFloat = 16
        static let shadowYOffset: CGFloat = -4
        static let shadowOpacity: Double = 0.08
    }
}
