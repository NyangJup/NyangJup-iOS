//
//  CatSpeechBubble.swift
//  NJPackage
//
//  Created by 정지훈 on 7/15/26.
//

import SwiftUI

import DomainCatsInterface
import SharedDesign

enum CatProfileHeroID: Hashable {
    case feed(String)
}

struct CatSpeechBubble: View {
    let cat: Cat
    let namespace: Namespace.ID
    var onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            catProfileInfo
            feedLink
        }
        .padding(.horizontal, Constant.horizontalPadding)
        .padding(.vertical, Constant.verticalPadding)
        .frame(width: Constant.bubbleWidth)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Constant.cornerRadius))
        .matchedTransitionSource(
            id: CatProfileHeroID.feed(cat.id),
            in: namespace
        )
        .contentShape(RoundedRectangle(cornerRadius: Constant.cornerRadius))
        .onTapGesture(perform: onTap)
    }
}

// MARK: - View

private extension CatSpeechBubble {
    var catProfileInfo: some View {
        CatProfileInfoView(
            cat: cat,
            imageBackgroundSize: Constant.imageBackgroundSize,
            catImageSize: Constant.catImageSize,
            contentSpacing: Constant.contentSpacing,
            informationSpacing: Constant.informationSpacing,
            nameFontSize: Constant.nameFontSize,
            nameFontWeight: .semibold,
            placeFontSize: Constant.placeFontSize,
            placeColor: .black.opacity(Constant.placeTextOpacity)
        )
    }

    var feedLink: some View {
        Text(Constant.feedTitle)
        .font(.system(size: Constant.feedFontSize, weight: .semibold))
        .padding(.leading, Constant.feedLabelPadding)
    }

}

// MARK: - Constant

private extension CatSpeechBubble {
    enum Constant {
        static let feedTitle: String = "피드 보기"

        static let bubbleWidth: CGFloat = 250
        static let imageBackgroundSize: CGFloat = 54
        static let catImageSize: CGFloat = 34
        static let contentSpacing: CGFloat = 16
        static let informationSpacing: CGFloat = 0
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 14
        static let feedLabelPadding: CGFloat = 4

        static let nameFontSize: CGFloat = 20
        static let placeFontSize: CGFloat = 17
        static let feedFontSize: CGFloat = 14
        static let placeTextOpacity: Double = 0.5

        static let cornerRadius: CGFloat = 16
    }
}
