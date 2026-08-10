//
//  GeneratedCatContentView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import SwiftUI

import CoreImageLoaderInterface
import SharedDesign

struct GeneratedCatContentView: View {
    let imageURL: URL?

    @Binding var name: String
    @Binding var place: String

    let isSubmitEnabled: Bool
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let imageURL {
                NZAsyncImage(
                    url: imageURL,
                    targetSize: Constant.imageTargetSize
                ) { image in
                    image
                        .resizable()
                        .scaledToFit()
                }
            }

            Spacer()

            CatNameFormView(
                name: $name,
                place: $place,
                isSubmitEnabled: isSubmitEnabled,
                onSubmit: onSubmit
            )
        }
        .background(
            NJImage.generateBackground.image
                .resizable()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
        )
    }
}

// MARK: - Constant

private extension GeneratedCatContentView {
    enum Constant {
        static let imageTargetSize = CGSize(width: 300, height: 300)
    }
}
