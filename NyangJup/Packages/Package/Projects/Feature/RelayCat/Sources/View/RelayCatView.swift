//
//  RelayCatView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/22/26.
//

import SwiftUI

import CoreAdsInterface
import FeatureCaptureInterface

struct RelayCatView: View {
    @Environment(\.captureFactory) private var captureFactory
    @Environment(\.nativeAdFactory) private var nativeAdFactory
    @Environment(\.displayScale) private var displayScale

    @State private var viewModel: RelayCatViewModel
    @State private var isDeleteAlertPresented = false

    init(viewModel: RelayCatViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.state.displayItems) { feedItem in
                        switch feedItem {
                        case let .relay(item):
                            RelayCatCell(
                                relayCat: item,
                                size: proxy.size,
                                isActive: viewModel.state.currentItemId == item.mediaId,
                                onHeartTapped: { isLiked in
                                    viewModel.send(.network(.updateIsLiked(
                                        id: item.mediaId,
                                        isLiked: isLiked
                                    )))
                                }
                            )
                            .id(item.mediaId)
                            .onAppear {
                                viewModel.send(.view(.itemAppeared(
                                    id: item.mediaId,
                                    size: proxy.size
                                )))
                            }

                        case let .ad(adItem):
                            nativeAdFactory.makeView(adItem)
                                .frame(
                                    width: proxy.size.width,
                                    height: proxy.size.height
                                )
                                .id(feedItem.id)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $viewModel.state.currentItemId)
        }
        .fullScreenCover(isPresented: $viewModel.state.isCameraPresented) {
            if let editingItem = viewModel.state.currentItem {
                captureFactory.makeView(
                    CaptureConfiguration(
                        showsModePicker: true,
                        catId: editingItem.catId,
                        editingMediaId: editingItem.mediaId,
                        mediaComment: editingItem.comment
                    ),
                    CaptureDelegate(send: { action in
                        switch action {
                        case let .complete(media):
                            viewModel.send(.view(.cameraCompleted(media)))
                        case .close:
                            viewModel.send(.view(.cameraDismissed))
                        case .register: break
                        }
                    })
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // 광고 페이지에서는 수정/삭제 메뉴를 숨긴다
                if viewModel.state.currentItem != nil {
                    Menu {
                        Button("수정") {
                            viewModel.send(.view(.editButtonTapped))
                        }
                        Button("삭제", role: .destructive) {
                            viewModel.send(.view(.deleteMenuButtonTapped))
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                    }
                    .tint(.white)
                }
            }
        }
        .alert("해당 콘텐츠를 삭제하시겠어요?", isPresented: $viewModel.state.isDeleteAlertPresented) {
            Button("네", role: .destructive) {
                viewModel.send(.view(.deleteButtonTapped))
            }
            
            Button("아니요", role: .cancel) {}
        }
        .background(.black)
        .onAppear { viewModel.send(.view(.onAppear(displayScale))) }
        .ignoresSafeArea()
    }
}
