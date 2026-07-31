//
//  FeedView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/15/26.
//

import SwiftUI

import DomainCatsInterface
import FeatureCaptureInterface
import SharedDesign

struct FeedView: View {
    @Environment(\.captureFactory) private var captureFactory

    @State var viewModel: FeedViewModel
    let namespace: Namespace.ID

    var body: some View {
        ScrollViewReader { scrollProxy in
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: Constant.sectionSpacing) {
                        profileHeader
                        Divider()
                        feedHeader
                        FeedList(
                            items: viewModel.state.items,
                            availableWidth: proxy.size.width - Constant.horizontalPadding * 2,
                            onTap: { media in
                                viewModel.send(.view(.feedContentTapped(media)))
                            },
                            onLoadNextPage: {
                                viewModel.send(.view(.loadNextPage))
                            }
                        )
                        Spacer()
                    }
                    .padding(.horizontal, Constant.horizontalPadding)
                    .padding(.top, Constant.topPadding)
                    .id(Constant.scrollTopID)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("수정") {
                            viewModel.send(.view(.editButtonTapped))
                        }

                        Button("삭제", role: .destructive) {
                            viewModel.send(.view(.deleteButtonTapped))
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                    }
                }
            }
            .alert("고양이 프로필 수정", isPresented: $viewModel.state.showsEditAlert) {
                TextField("이름", text: $viewModel.state.editName)
                    .padding(.trailing, 32)
                    .onChange(of: viewModel.state.editName) { _, newValue in
                        if newValue.count > FeedViewModel.nameMaxLength {
                            viewModel.state.editName = String(
                                newValue.prefix(FeedViewModel.nameMaxLength)
                            )
                        }
                    }

                TextField("장소", text: $viewModel.state.editPlace)
                    .padding(.trailing, 40)
                    .onChange(of: viewModel.state.editPlace) { _, newValue in
                        if newValue.count > FeedViewModel.placeMaxLength {
                            viewModel.state.editPlace = String(
                                newValue.prefix(FeedViewModel.placeMaxLength)
                            )
                        }
                    }

                Button("저장") {
                    viewModel.send(.view(.updateProfileAlertTapped))
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!viewModel.state.canUpdateProfile)

                Button("취소", role: .cancel) { }
            }
            .alert("고양이를 삭제할까요?", isPresented: $viewModel.state.showsDeleteAlert) {
                Button("네", role: .destructive) {
                    viewModel.send(.view(.deleteAlertTapped))
                }

                Button("아니요", role: .cancel) { }
            } message: {
                Text("피드 콘텐츠도 전부 사라져요.")
            }
            .overlay(alignment: .bottomTrailing) {
                plusButton
            }
            .ignoresSafeArea()
            .navigationTransition(
                .zoom(
                    sourceID: CatProfileHeroID.feed(viewModel.state.cat.id),
                    in: namespace
                )
            )
            .fullScreenCover(isPresented: $viewModel.state.isCameraPresented) {
                captureFactory.makeView(
                    CaptureConfiguration(
                        showsModePicker: true,
                        cat: viewModel.state.cat
                    ),
                    CaptureDelegate(send: { action in
                        switch action {
                        case let .complete(media):
                            viewModel.send(.view(.cameraCompleted(media)))
                            scrollProxy.scrollTo(Constant.scrollTopID, anchor: .top)
                        case .close:
                            viewModel.send(.view(.cameraDismissed))
                        }
                    })
                )
            }
            .onAppear {
                viewModel.send(.view(.onAppear))
            }
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

// MARK: - Constant

private extension FeedView {
    enum Constant {
        static let bottomButtonImage: String = "plus"
        static let closeImageName: String = "xmark"
        static let feedTitle: String = "피드"
        static let scrollTopID: String = "feed-scroll-top"

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
        
        static let bottomButtonImageSize: CGFloat = 24
        static let bottomButtonSize: CGFloat = 60
        static let bottomButtonTrailingPadding: CGFloat = 20
        static let bottomButtonBottomPadding: CGFloat = 48
    }
}
