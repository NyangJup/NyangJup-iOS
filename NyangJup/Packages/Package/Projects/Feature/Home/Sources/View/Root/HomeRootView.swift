//
//  HomeRootView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/15/26.
//

import SwiftUI

import DomainCatsInterface
import DomainProfileInterface
import FeatureHomeInterface

public struct HomeRootView: View {
    @State private var homeViewModel: HomeViewModel
    @State private var coordinator: HomeCoordinator
    @Namespace private var catProfileNamespace

    public init(
        catsClient: CatsClient,
        profileClient: ProfileClient
    ) {
        let coordinator = HomeCoordinator()
        self._homeViewModel = State(initialValue: HomeViewModel(
            catsClient: catsClient,
            profileClient: profileClient,
            coordinator: coordinator
        ))
        self._coordinator = State(initialValue: coordinator)
    }

    public var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeView(
                viewModel: homeViewModel,
                namespace: catProfileNamespace
            )
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case let .feed(catId):
                    if let cat = homeViewModel.state.cats.first(where: { $0.id == catId }) {
                        FeedView(
                            cat: cat,
                            namespace: catProfileNamespace
                        )
                    }
                }
            }
        }
    }
}
