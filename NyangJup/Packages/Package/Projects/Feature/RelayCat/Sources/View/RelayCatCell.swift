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
            mediaContent
            catInfo
            heartButton
        }
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder
    private var mediaContent: some View {
        if let url = URL(string: relayCat.mediaURL) {
            switch relayCat.mediaType {
            case .photo:
                NZAsyncImage(
                    url: url,
                    targetSize: size
                ) { image in
                    image
                        .resizable()
                        .scaledToFit()
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, Constant.photoTopPadding)

            case .video:
                RelayVideo(
                    url: url,
                    isActive: isActive
                )
            }
        }
    }

    private var catInfo: some View {
        VStack(
            alignment: .leading,
            spacing: Constant.contentSpacing
        ) {
            Spacer()

            HStack {
                CatAvatarView(
                    image: NJImage.koreanShorthair.image,
                    backgroundSize: Constant.avatarBackgroundSize,
                    imageSize: Constant.avatarImageSize
                )

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

            Text(relayCat.memo)
                .font(
                    .system(
                        size: Constant.memoFontSize,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.white)
        }
        .padding(.horizontal, Constant.horizontalPadding)
        .padding(.bottom, Constant.infoBottomPadding)
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

        static let likedImageName = "heart.fill"
        static let unlikedImageName = "heart"
        static let heartImageSize: CGFloat = 24
        static let heartFrameSize: CGFloat = 26
        static let heartDebounceDuration: Duration = .milliseconds(300)
    }
}
