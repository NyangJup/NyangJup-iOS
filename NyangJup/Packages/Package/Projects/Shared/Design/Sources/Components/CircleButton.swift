//
//  CircleButton.swift
//  NJPackage
//
//  Created by 정지훈 on 7/27/26.
//

import SwiftUI

public struct CircleButton: View {
    let onTap: () -> Void
    let image: Image
    let glassEffect: Glass
    let buttonSize: CGSize
    let imageSize: CGSize
    let foregroundColor: Color
    
    public init(
        onTap: @escaping () -> Void,
        image: Image,
        glassEffect: Glass?,
        buttonSize: CGSize,
        imageSize: CGSize,
        foregroundColor: Color
    ) {
        self.onTap = onTap
        self.image = image
        self.glassEffect = glassEffect ?? .identity
        self.buttonSize = buttonSize
        self.imageSize = imageSize
        self.foregroundColor = foregroundColor
    }
    
    public var body: some View {
        Button {
            onTap()
        } label: {
            image
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(foregroundColor)
                .frame(width: imageSize.width, height: imageSize.height)
        }
        .frame(width: buttonSize.width, height: buttonSize.height)
        .glassEffect(glassEffect, in: .circle)
    }
    
}
