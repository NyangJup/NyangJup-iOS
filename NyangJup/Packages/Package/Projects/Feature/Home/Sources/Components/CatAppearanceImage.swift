//
//  CatAppearanceImage.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import SwiftUI

struct CatAppearanceImage: View {
    @Binding var selectedCatIndex: Int
    let catAppearances: [CatAppearance]

    var body: some View {
        catAppearances[selectedCatIndex].imageAsset.image
            .resizable()
            .scaledToFit()
            .frame(width: Constant.imageSize, height: Constant.imageSize)
    }
}

// MARK: - Constant

private extension CatAppearanceImage {
    enum Constant {
        static let imageSize: CGFloat = 180
    }
}
