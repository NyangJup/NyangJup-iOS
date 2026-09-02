//
//  RelayCatCell.swift
//  NJPackage
//
//  Created by 정지훈 on 7/23/26.
//

import SwiftUI

import CoreImageLoaderInterface
import DomainMediaInterface
import SharedDesign

struct RelayCatCell: View {
    @State private var displayedIsLiked: Bool

    let relayCat: RelayCat
    let size: CGSize
    let isActive: Bool
    let onHeartTapped: (Bool) -> Void

    init(
        relayCat: RelayCat,
        size: CGSize,
        isActive: Bool,
        onHeartTapped: @escaping (Bool) -> Void
    ) {
        self._displayedIsLiked = State(initialValue: relayCat.isLiked)
        self.relayCat = relayCat
        self.size = size
        self.isActive = isActive
        self.onHeartTapped = onHeartTapped
    }

    var body: some View {
        ZStack {
            switch relayCat.mediaType {
            case .photo:
                VStack(spacing: 0) {
                    photoContent

                    catInfo
                        .fixedSize(horizontal: false, vertical: true)
                }

            case .video:
                ZStack(alignment: .bottomLeading) {
                    videoContent
                    catInfo
                }
            }

            heartButton
        }
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder
    private var photoContent: some View {
        if let url = URL(string: relayCat.mediaURL) {
            NZAsyncImage(
                url: url,
                targetSize: size
            ) { image, _ in
                image
                    .resizable()
                    .scaledToFit()
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .center
            )
        }
    }

    @ViewBuilder
    private var videoContent: some View {
        if let url = URL(string: relayCat.mediaURL) {
            RelayVideo(
                url: url,
                isActive: isActive
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var catInfo: some View {
        VStack(
            alignment: .leading,
            spacing: Constant.contentSpacing
        ) {
            HStack {
                catAvatar

                Text(relayCat.name)
                    .font(
                        .system(
                            size: Constant.nameFontSize,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)

                Spacer()
            }

            if let place = relayCat.place, !place.isEmpty {
                Label(place, systemImage: Constant.placeImageName)
                    .font(
                        .system(
                            size: Constant.placeFontSize,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.white)
            }

            Text(relayCat.comment)
                .font(
                    .system(
                        size: Constant.memoFontSize,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Constant.horizontalPadding)
        .padding(.bottom, Constant.infoBottomPadding)
    }

    @ViewBuilder
    private var catAvatar: some View {
        if let imageURL = URL(string: relayCat.catImageURL) {
            NZAsyncImage(
                url: imageURL,
                targetSize: CGSize(
                    width: Constant.avatarImageSize,
                    height: Constant.avatarImageSize
                ), content: { image in
                       CatAvatarView(
                           image: image,
                           backgroundSize: Constant.avatarBackgroundSize,
                           imageSize: Constant.avatarImageSize
                       )
                }, placeholder: {
                    Circle()
                        .fill(.gray.opacity(0.8))
                        .frame(
                            width: Constant.avatarBackgroundSize,
                            height: Constant.avatarBackgroundSize
                        )
                }
            )
        }
    }

    private var heartButton: some View {
        VStack(spacing: Constant.contentSpacing) {
            Spacer()

            Button {
                displayedIsLiked.toggle()
            } label: {
                Image(
                    systemName: displayedIsLiked
                        ? Constant.likedImageName
                        : Constant.unlikedImageName
                )
                .font(
                    .system(
                        size: Constant.heartImageSize,
                        weight: .semibold
                    )
                )
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: displayedIsLiked)
                .foregroundStyle(displayedIsLiked ? .red : .white)
                .frame(
                    width: Constant.heartFrameSize,
                    height: Constant.heartFrameSize
                )
            }
            .buttonStyle(.plain)
            .debounce(
                value: displayedIsLiked,
                for: Constant.heartDebounceDuration,
                perform: onHeartTapped
            )
            .onChange(of: relayCat.isLiked) { _, isLiked in
                displayedIsLiked = isLiked
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, Constant.horizontalPadding)
        .padding(.bottom, Constant.heartBottomPadding)
    }

}

private extension RelayCatCell {
    enum Constant {
        static let photoTopPadding: CGFloat = 100
        static let contentSpacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let infoBottomPadding: CGFloat = 80
        static let heartBottomPadding: CGFloat = 200
        static let avatarBackgroundSize: CGFloat = 38
        static let avatarImageSize: CGFloat = 26
        static let nameFontSize: CGFloat = 15
        static let memoFontSize: CGFloat = 13
        static let placeFontSize: CGFloat = 12
        static let placeImageName = "mappin.and.ellipse"

        static let likedImageName = "heart.fill"
        static let unlikedImageName = "heart"
        static let heartImageSize: CGFloat = 24
        static let heartFrameSize: CGFloat = 26
        static let heartDebounceDuration: Duration = .milliseconds(300)
    }
}
