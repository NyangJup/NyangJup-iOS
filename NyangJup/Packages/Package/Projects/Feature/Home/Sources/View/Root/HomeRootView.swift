//
//  HomeRootView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/15/26.
//

import SwiftUI

import DomainCatsInterface
import DomainMediaInterface
import DomainProfileInterface
import FeatureHomeInterface
import FeatureRelayCatInterface

public struct HomeRootView: View {
    @Environment(\.relayCatFactory) private var relayCatFactory
    
    @Namespace private var catProfileNamespace
    
    @State private var homeViewModel: HomeViewModel
    @State private var coordinator: HomeCoordinator
    
    private let mediaClient: MediaClient
    
    public init(
        catsClient: CatsClient,
        profileClient: ProfileClient,
        mediaClient: MediaClient
    ) {
        let coordinator = HomeCoordinator()
        self._homeViewModel = State(initialValue: HomeViewModel(
            catsClient: catsClient,
            profileClient: profileClient,
            coordinator: coordinator
        ))
        self._coordinator = State(initialValue: coordinator)
        self.mediaClient = mediaClient
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
                            viewModel: FeedViewModel(
                                cat: cat,
                                mediaClient: mediaClient,
                                coordinator: coordinator
                            ),
                            namespace: catProfileNamespace
                        )
                    }
                    
                case let .relayCat(relayCat, catId):
                    relayCatFactory.makeView(
                        RelayCatConfiguration(
                            relayCat: relayCat,
                            catId: catId
                        ),
                        nil
                    )
                }
            }
        }
    }
}
