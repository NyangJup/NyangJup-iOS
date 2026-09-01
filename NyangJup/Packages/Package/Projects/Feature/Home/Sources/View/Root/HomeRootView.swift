//
//  HomeRootView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/15/26.
//

import SwiftUI

import CoreAdsInterface
import DomainCatsInterface
import DomainMediaInterface
import DomainPixelRewardInterface
import DomainProfileInterface
import FeatureHomeInterface
import FeatureRelayCatInterface

public struct HomeRootView: View {
    @Environment(\.relayCatFactory) private var relayCatFactory
    
    @Namespace private var catProfileNamespace
    
    @State private var homeViewModel: HomeViewModel
    @State private var coordinator: HomeCoordinator
    
    private let catsClient: CatsClient
    private let mediaClient: MediaClient
    private let adsClient: AdsClient
    
    public init(
        catsClient: CatsClient,
        profileClient: ProfileClient,
        mediaClient: MediaClient,
        adsClient: AdsClient,
        pixelRewardClient: PixelRewardClient
    ) {
        let coordinator = HomeCoordinator()
        self._homeViewModel = State(initialValue: HomeViewModel(
            catsClient: catsClient,
            profileClient: profileClient,
            adsClient: adsClient,
            pixelRewardClient: pixelRewardClient,
            coordinator: coordinator
        ))
        self._coordinator = State(initialValue: coordinator)
        self.catsClient = catsClient
        self.mediaClient = mediaClient
        self.adsClient = adsClient
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
                                catsClient: catsClient,
                                mediaClient: mediaClient,
                                onCatDeleted: { id in
                                    homeViewModel.send(.internal(.catDeleted(id: id)))
                                },
                                onCatUpdated: { cat in
                                    homeViewModel.send(.internal(.catUpdated(cat)))
                                },
                                coordinator: coordinator
                            ),
                            namespace: catProfileNamespace
                        )
                    }
                    
                case let .relayCat(relayCat):
                    relayCatFactory.makeView(
                        RelayCatConfiguration(
                            relayCat: relayCat
                        ),
                        nil
                    )
                }
            }
        }
    }
}
