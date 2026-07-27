//
//  SwiftUIView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/15/26.
//

import SwiftUI

import DomainCatsInterface
import SharedDesign

struct CatProfileInfoView: View {
    let cat: Cat
    let imageBackgroundSize: CGFloat
    let catImageSize: CGFloat
    let contentSpacing: CGFloat
    let informationSpacing: CGFloat
    let nameFontSize: CGFloat
    let nameFontWeight: Font.Weight
    let placeFontSize: CGFloat
    let placeColor: Color

    var body: some View {
        HStack(spacing: contentSpacing) {
            CatAvatarView(
                image: catImage,
                backgroundSize: imageBackgroundSize,
                imageSize: catImageSize
            )
            catInformation
            Spacer()
        }
    }
}

// MARK: - View

private extension CatProfileInfoView {
    var catInformation: some View {
        VStack(alignment: .leading, spacing: informationSpacing) {
            Text(cat.name)
                .font(.system(
                    size: nameFontSize,
                    weight: nameFontWeight
                ))

            if let place = cat.place, !place.isEmpty {
                placeView(place)
            }
        }
    }

    @ViewBuilder
    func placeView(_ place: String) -> some View {
        Text(place)
            .font(.system(size: placeFontSize))
            .foregroundStyle(placeColor)
    }

    var catImage: Image {
        guard let appearance = CatAppearance(rawValue: cat.appearanceKey) else {
            return NJImage.catFoot.image
        }

        return appearance.imageAsset.image
    }
}
