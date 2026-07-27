//
//  RelayCatView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/22/26.
//

import SwiftUI

struct RelayCatView: View {
    @Environment(\.displayScale) private var displayScale

    @State private var viewModel: RelayCatViewModel

    init(viewModel: RelayCatViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.state.items, id: \.id) { item in
                        RelayCatCell(
                            relayCat: item,
                            size: proxy.size,
                            isActive: viewModel.state.currentItemId == item.id,
                            onHeartTapped: { isLiked in
                                viewModel.send(.network(.updateIsLiked(
                                    id: item.id,
                                    isLiked: isLiked
                                )))
                            }
                        )
                        .id(item.id)
                        .onAppear {
                            viewModel.send(.view(.itemAppeared(
                                id: item.id,
                                size: proxy.size
                            )))
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $viewModel.state.currentItemId)
        }
        .background(.black)
        .onAppear { viewModel.send(.view(.onAppear(displayScale))) }
        .ignoresSafeArea()
    }
}
