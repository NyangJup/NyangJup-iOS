//
//  CreatingContentView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import SwiftUI

struct CreatingContentView: View {
    let isGenerated: Bool
    let onShowGeneratedImageTapped: () -> Void

    var body: some View {
        VStack {
            if let rhythmURL = Constant.rhythmURL {
                WebView(url: rhythmURL)
                    .frame(height: Constant.webViewHeight)
            }

            Text(
                isGenerated
                    ? Constant.generatedText
                    : Constant.generatingText
            )
            .font(.headline)

            if isGenerated {
                showGeneratedImageButton
            }
        }
    }
}

// MARK: - View

private extension CreatingContentView {
    var showGeneratedImageButton: some View {
        Button(action: onShowGeneratedImageTapped) {
            Text(Constant.showGeneratedImageButtonText)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Constant.buttonHeight)
                .background(
                    .red.opacity(
                        Constant.submitButtonOpacity
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: Constant.buttonCornerRadius
                    )
                )
        }
        .padding(.horizontal, Constant.horizontalPadding)
    }
}

// MARK: - Constant

private extension CreatingContentView {
    enum Constant {
        static let rhythmURL: URL? = {
            guard let urlString = Bundle.main.object(
                forInfoDictionaryKey: miniGameURLKey
            ) as? String else {
                return nil
            }

            return URL(string: urlString)
        }()

        static let miniGameURLKey = "MiniGameURL"

        static let generatingText = "고양이 이미지 생성중..."
        static let generatedText = "이미지가 다 생성됐어요!"
        static let showGeneratedImageButtonText = "보러가기"

        static let submitButtonOpacity: Double = 0.7
        static let webViewHeight: CGFloat = 400
        static let horizontalPadding: CGFloat = 20
        static let buttonHeight: CGFloat = 52
        static let buttonCornerRadius: CGFloat = 12
    }
}
