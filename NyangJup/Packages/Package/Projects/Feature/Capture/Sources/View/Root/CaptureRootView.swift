//
//  CaptureRootView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/13/26.
//

import SwiftUI

import FeatureCaptureInterface

struct CaptureRootView: View {
    @State private var captureViewModel: CaptureViewModel
    @State private var coordinator: CaptureCoordinator
    
    private let onAction: @MainActor @Sendable (CaptureDelegate.Action) -> Void

    init(
        viewModel: CaptureViewModel,
        coordinator: CaptureCoordinator,
        onAction: @escaping @MainActor @Sendable (CaptureDelegate.Action) -> Void
    ) {
        self._captureViewModel = State(initialValue: viewModel)
        self._coordinator = State(initialValue: coordinator)
        self.onAction = onAction
    }
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            CaptureView(
                viewModel: captureViewModel,
                onAction: onAction
            )
            .navigationDestination(for: CaptureRoute.self) { route in
                switch route {
                case .upload:
                    EmptyView()
                }
            }
        }
    }
}
