//
//  FeedView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/15/26.
//

import SwiftUI

import DomainCatsInterface

struct FeedView: View {
    @State var viewModel: FeedViewModel
    let namespace: Namespace.ID

    var body: some View {
        ScrollView {
            VStack(spacing: Constant.sectionSpacing) {
                profileHeader
                feedHeader
                FeedList(items: viewModel.state.items)
                Spacer()
            }
            .padding(.horizontal, Constant.horizontalPadding)
            .padding(.top, Constant.topPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .navigationTransition(
            .zoom(
                sourceID: CatProfileHeroID.feed(viewModel.state.cat.id),
                in: namespace
            )
        )
        .onAppear {
            viewModel.send(.view(.onAppear))
        }
    }
}

// MARK: - View

private extension FeedView {
    var profileHeader: some View {
        CatProfileInfoView(
            cat: viewModel.state.cat,
            imageBackgroundSize: Constant.avatarBackgroundSize,
            catImageSize: Constant.catImageSize,
            contentSpacing: Constant.profileSpacing,
            informationSpacing: Constant.informationSpacing,
            nameFontSize: Constant.nameFontSize,
            nameFontWeight: .bold,
            placeFontSize: Constant.placeFontSize,
            placeColor: .secondary
        )
        .padding(.top, Constant.profileTopPadding)
        .padding(.bottom, Constant.profileBottomPadding)
    }

    var feedHeader: some View {
        HStack {
            Text(Constant.feedTitle)
                .font(.system(
                    size: Constant.feedTitleFontSize,
                    weight: .bold
                ))

            Spacer()
        }
    }
}

// MARK: - Constant

private extension FeedView {
    enum Constant {
        static let closeImageName: String = "xmark"
        static let feedTitle: String = "피드"

        static let horizontalPadding: CGFloat = 24
        static let topPadding: CGFloat = 60
        static let sectionSpacing: CGFloat = 16
        static let closeImageSize: CGFloat = 20
        static let profileSpacing: CGFloat = 24
        static let profileTopPadding: CGFloat = 60
        static let profileBottomPadding: CGFloat = 20
        static let avatarBackgroundSize: CGFloat = 96
        static let catImageSize: CGFloat = 64
        static let informationSpacing: CGFloat = 8
        static let nameFontSize: CGFloat = 30
        static let placeFontSize: CGFloat = 15
        static let feedTitleFontSize: CGFloat = 24
    }
}
