//
//  GenerateCatView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import SwiftUI

import SharedDesign

struct GenerateCatView: View {
    @State private var name: String = ""
    @State private var selectedCatIndex: Int = 0
    let onSubmit: (String, String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            catAppearancePicker

            Spacer()

            catNameForm
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            NJImage.generateBackground.image
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
        .onAppear {
            selectedCatIndex = Constant.catAppearances.indices.randomElement() ?? 0
        }
    }
}

// MARK: - View

private extension GenerateCatView {
    var catAppearancePicker: some View {
        ZStack {
            CatAppearanceImage(
                selectedCatIndex: $selectedCatIndex,
                catAppearances: Constant.catAppearances
            )

            HStack {
                previousButton
                Spacer()
                nextButton
            }
            .padding(.horizontal, Constant.horizontalPadding)
        }
    }

    var previousButton: some View {
        appearanceNavigationButton(
            systemName: Constant.previousImage,
            action: selectPreviousCat
        )
    }

    var nextButton: some View {
        appearanceNavigationButton(
            systemName: Constant.nextImage,
            action: selectNextCat
        )
    }

    func appearanceNavigationButton(
        systemName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: Constant.navigationImageSize, weight: .bold))
                .foregroundStyle(.black)
                .frame(
                    width: Constant.navigationButtonSize,
                    height: Constant.navigationButtonSize
                )
        }
        .glassEffect(.regular.interactive())
    }

    var catNameForm: some View {
        VStack(alignment: .leading, spacing: Constant.contentSpacing) {
            title
            NJTextField(
                text: $name,
                placeholder: Constant.namePlaceholder,
                maxLength: Constant.nameMaxLength
            )
            NJButton(
                text: Constant.submitButtonText,
                backgroundColor: .red.opacity(Constant.submitButtonOpacity),
                foregroundColor: .white,
                isEnabled: !name.isEmpty,
                onTap: submit
            )
        }
        .padding(.horizontal, Constant.horizontalPadding)
        .padding(.top, Constant.formTopPadding)
        .padding(.bottom, Constant.formBottomPadding)
        .frame(maxWidth: .infinity)
        .background(formBackground)
    }

    var title: some View {
        Text(Constant.title)
            .font(.system(size: Constant.titleFontSize, weight: .bold))
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
            color: .black.opacity(Constant.shadowOpacity),
            radius: Constant.shadowRadius,
            y: Constant.shadowYOffset
        )
    }
}

// MARK: - Action

private extension GenerateCatView {
    func selectPreviousCat() {
        selectedCatIndex = (
            selectedCatIndex - 1 + Constant.catAppearances.count
        ) % Constant.catAppearances.count
    }

    func selectNextCat() {
        selectedCatIndex = (
            selectedCatIndex + 1
        ) % Constant.catAppearances.count
    }

    func submit() {
        onSubmit(name, Constant.catAppearances[selectedCatIndex].rawValue)
    }
}

// MARK: - Constant

private extension GenerateCatView {
    enum Constant {
        static let catAppearances = CatAppearance.allCases

        static let previousImage = "chevron.left"
        static let nextImage = "chevron.right"
        static let title = "이름을 지어주세요!"
        static let namePlaceholder = "이름"
        static let nameMaxLength = 5
        static let submitButtonText = "확인"
        static let submitButtonOpacity: Double = 0.7
        static let navigationImageSize: CGFloat = 16
        static let navigationButtonSize: CGFloat = 32
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
