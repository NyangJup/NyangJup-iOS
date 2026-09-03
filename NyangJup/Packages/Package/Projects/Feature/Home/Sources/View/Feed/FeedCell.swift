//
//  FeedCell.swift
//  NJPackage
//
//  Created by 정지훈 on 7/22/26.
//

import SwiftUI

import CoreImageLoaderInterface
import DomainMediaInterface

struct FeedCell: View {
    let media: Media
    let targetSize: CGSize
    
    let onTap: (Media) -> Void

    var body: some View {
        Group {
            if let url = media.thumbnailURL.flatMap(URL.init(string:)) {
                NZAsyncImage(
                    url: url,
                    targetSize: targetSize
                ) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(
            width: targetSize.width,
            height: targetSize.height
        )
        .overlay(alignment: .topTrailing) {
            if media.mediaType == .video {
                Image(systemName: Constant.playImageName)
                    .font(.system(size: Constant.playImageSize, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(Constant.playImagePadding)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if media.isLiked {
                Image(systemName: Constant.likedImageName)
                    .font(.system(size: Constant.heartImageSize, weight: .semibold))
                    .foregroundStyle(.red)
                    .padding(Constant.heartImagePadding)
            }
        }
        .clipShape(.rect(cornerRadius: Constant.cornerRadius))
        .onTapGesture { onTap(media) }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(.gray.opacity(0.8))
    }
}


private extension FeedCell {
    enum Constant {
        static let cornerRadius: CGFloat = 16
        static let playImageName: String = "play.square.fill"
        static let playImageSize: CGFloat = 16
        static let playImagePadding: CGFloat = 12
        static let likedImageName = "heart.fill"
        static let heartImageSize: CGFloat = 18
        static let heartImagePadding: CGFloat = 12
    }
}
