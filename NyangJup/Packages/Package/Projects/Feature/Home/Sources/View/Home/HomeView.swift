//
//  HomeView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import SwiftUI

import FeatureCaptureInterface
import SharedDesign

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
            catCountView
        }
        .overlay(alignment: .bottomTrailing) {
            plusButton
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.send(.view(.onAppear))
        }
        .sheet(isPresented: $viewModel.state.isMakeCatPresented) {
            generateCatView
        }
        .alert(
            Constant.catLimitAlertTitle,
            isPresented: $viewModel.state.showsCatLimitAlert
        ) {
            Button(Constant.confirmButtonTitle, role: .cancel) { }
        } message: {
            Text(Constant.catLimitAlertMessage)
        }
    }
}

// MARK: - UI

private extension HomeView {
    var catCountView: some View {
        Text("\(viewModel.state.cats.count)/\(HomeViewModel.maximumCatCount)")
            .font(.system(
                size: Constant.catCountFontSize,
                weight: .semibold,
                design: .rounded
            ))
            .monospacedDigit()
            .padding(.horizontal, Constant.catCountHorizontalPadding)
            .padding(.vertical, Constant.catCountVerticalPadding)
            .glassEffect(.regular, in: Capsule())
            .padding(.leading, Constant.catCountLeadingPadding)
            .padding(.top, Constant.catCountTopPadding)
    }

    var mapView: some View {
        HomeMapView(
            cats: viewModel.state.cats,
            selectedCatID: viewModel.state.selectedCatId,
            onCatTapped: { id, position in
                selectedCatPosition = position
                viewModel.send(.view(.catTapped(id: id)))
            },
            onSelectionCleared: {
                selectedCatPosition = nil
                viewModel.send(.view(.selectionCleared))
            }
        )
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

    var generateCatView: some View {
        GenerateCatView { name, appearanceKey in
            viewModel.send(.view(.makeCatSubmitted(
                name: name,
                appearanceKey: appearanceKey
            )))
        }
    }
    
    var plusButton: some View {
        CircleButton(
            onTap: { viewModel.send(.view(.plusButtonTapped)) },
            image: Image(systemName: Constant.bottomButtonImage),
            glassEffect: .regular.interactive(),
            buttonSize: CGSize(
                width: Constant.bottomButtonSize,
                height: Constant.bottomButtonSize
            ),
            imageSize: CGSize(
                width: Constant.bottomButtonImageSize,
                height: Constant.bottomButtonImageSize
            ),
            foregroundColor: .black
        )
        .padding(.trailing, Constant.bottomButtonTrailingPadding)
        .padding(.bottom, Constant.bottomButtonBottomPadding)
    }
}

// MARK: - Constants

private extension HomeView {
    private enum Constant {
        static let bottomButtonImage: String = "plus"
        static let catLimitAlertTitle = "최대 \(HomeViewModel.maximumCatCount)마리까지 냥줍할 수 있어요"
        static let catLimitAlertMessage = "추후 업데이트에서 더 많은 냥줍을 지원할 예정이에요."
        static let confirmButtonTitle = "확인"

        static let catCountFontSize: CGFloat = 16
        static let catCountHorizontalPadding: CGFloat = 14
        static let catCountVerticalPadding: CGFloat = 10
        static let catCountLeadingPadding: CGFloat = 24
        static let catCountTopPadding: CGFloat = 60
        
        static let bottomButtonImageSize: CGFloat = 24
        static let bottomButtonSize: CGFloat = 60
        static let bottomButtonTrailingPadding: CGFloat = 20
        static let bottomButtonBottomPadding: CGFloat = 48
    }
}
