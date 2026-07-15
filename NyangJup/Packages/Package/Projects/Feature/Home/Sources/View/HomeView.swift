//
//  HomeView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import SwiftUI
import SpriteKit

import FeatureCaptureInterface

public struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var selectedCatPosition: CGPoint?
    private let namespace: Namespace.ID

    init(
        viewModel: HomeViewModel,
        namespace: Namespace.ID
    ) {
        self.viewModel = viewModel
        self.namespace = namespace
    }

    public var body: some View {
        ZStack {
            mapView
            catSpeechBubble
        }
        .overlay(alignment: .topLeading) {
            titleView
        }
        .overlay(alignment: .bottomTrailing) {
            bottomButton
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.send(.view(.onAppear))
        }
        .sheet(isPresented: $viewModel.state.isMakeCatPresented) {
            GenerateCatView { name, appearanceKey in
                viewModel.send(.view(.makeCatSubmitted(
                    name: name,
                    appearanceKey: appearanceKey
                )))
            }
        }
    }
}

// MARK: - UI

private extension HomeView {
    var mapView: some View {
        GeometryReader { proxy in
            SpriteView(
                scene: HomeMapScene(
                    size: proxy.size,
                    cats: viewModel.state.cats,
                    onCatTapped: { id, position in
                        selectedCatPosition = position
                        viewModel.send(.view(.catTapped(id: id)))
                    },
                    onSelectionCleared: {
                        selectedCatPosition = nil
                        viewModel.send(.view(.selectionCleared))
                    }
                ),
                options: [.allowsTransparency]
            )
            .id(viewModel.state.cats.map(\.id).joined())
        }
    }

    @ViewBuilder
    var catSpeechBubble: some View {
        if let cat = viewModel.state.selectedCat,
           let position = selectedCatPosition {
            CatSpeechBubble(
                cat: cat,
                namespace: namespace,
                onTap: {
                    viewModel.send(.view(.speechBubbleTapped))
                }
            )
            .position(position)
        }
    }

    var titleView: some View {
        Text(Constant.title)
            .font(.largeTitle)
            .padding(.leading, Constant.titleLeadingPadding)
            .padding(.top, Constant.titleTopPadding)
    }

    var bottomButton: some View {
        Button {
            viewModel.send(.view(.plusButtonTapped))
        } label: {
            bottomButtonImage
        }
        .frame(width: Constant.bottomButtonSize, height: Constant.bottomButtonSize)
        .glassEffect(.clear.interactive(), in: .circle)
        .padding(.trailing, Constant.bottomButtonTrailingPadding)
        .padding(.bottom, Constant.bottomButtonBottomPadding)
    }

    var bottomButtonImage: some View {
        Image(systemName: Constant.bottomButtonImage)
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(.black)
            .frame(width: Constant.bottomButtonImageSize, height: Constant.bottomButtonImageSize)
    }
}

// MARK: - Constants

private extension HomeView {
    private enum Constant {
        static let title: String = "냥줍"
        static let bottomButtonImage: String = "plus"

        static let titleLeadingPadding: CGFloat = 32
        static let titleTopPadding: CGFloat = 60

        static let bottomButtonImageSize: CGFloat = 24
        static let bottomButtonSize: CGFloat = 60
        static let bottomButtonTrailingPadding: CGFloat = 20
        static let bottomButtonBottomPadding: CGFloat = 48

    }
}
