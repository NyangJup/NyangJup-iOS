//
//  GenerateCatView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import SwiftUI

struct GenerateCatView: View {

    @State private var viewModel: GenerateCatViewModel

    init(viewModel: GenerateCatViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            if let isCreating = viewModel.state.isCreating {
                if isCreating {
                    CreatingContentView(
                        isGenerated: viewModel.state.isGenerated,
                        onShowGeneratedImageTapped: {
                            viewModel.send(
                                .view(.showGeneratedImageButtonTapped)
                            )
                        }
                    )
                    .transition(.opacity)
                } else {
                    GeneratedCatContentView(
                        imageURL: viewModel.state.pixelImageURL,
                        name: $viewModel.state.name,
                        place: $viewModel.state.place,
                        isSubmitEnabled: !viewModel.state.name.isEmpty
                            && !viewModel.state.place.isEmpty,
                        onSubmit: {
                            viewModel.send(
                                .view(.submitButtonTapped)
                            )
                        }
                    )
                    .transition(.opacity)
                }
            }
        }
        .animation(
            .easeInOut(duration: 0.4),
            value: viewModel.state.isCreating
        )
        .onAppear {
            viewModel.send(.view(.onAppear))
        }
        .loadingOverlay(
            isPresented: viewModel.state.isLoading
        )
        .alert(
            viewModel.state.errorMessage ?? "",
            isPresented: $viewModel.state.isAlertPrsented
        ) {
            Button("확인") {
                viewModel.send(
                    .view(.alertConfirmTapped)
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}
