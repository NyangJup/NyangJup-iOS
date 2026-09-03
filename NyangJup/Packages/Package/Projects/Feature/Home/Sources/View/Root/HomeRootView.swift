//
//  HomeRootView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/15/26.
//

import SwiftUI

import CoreAdsInterface
import DomainCatsInterface
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
    private let adsClient: AdsClient
    
    public init(
        catsClient: CatsClient,
        profileClient: ProfileClient,
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
                        coordinator.relayCatDelegate(for: relayCat.mediaId)
                    )
                }
            }
        }
    }
}
