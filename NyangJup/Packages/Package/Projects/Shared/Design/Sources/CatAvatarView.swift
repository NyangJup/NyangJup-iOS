//
//  CatAvatarView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/23/26.
//

import SwiftUI

public struct CatAvatarView: View {
    private let image: Image
    private let backgroundSize: CGFloat
    private let imageSize: CGFloat

    public init(
        image: Image,
        backgroundSize: CGFloat,
        imageSize: CGFloat
    ) {
        self.image = image
        self.backgroundSize = backgroundSize
        self.imageSize = imageSize
    }

    public var body: some View {
        ZStack {
            NJImage.generateBackground.image
                .resizable()
                .frame(
                    width: backgroundSize,
                    height: backgroundSize
                )
                .clipShape(.circle)

            image
                .resizable()
                .scaledToFit()
                .frame(
                    width: imageSize,
                    height: imageSize
                )
        }
    }
}
