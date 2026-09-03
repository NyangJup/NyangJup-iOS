//
//  HomeCoordinator.swift
//  NJPackage
//
//  Created by 정지훈 on 7/15/26.
//

import Foundation

import FeatureCommonInterface
import FeatureHomeInterface
import FeatureRelayCatInterface

@MainActor
@Observable
final class HomeCoordinator: Coordinator {
    typealias Route = HomeRoute

    var path: [HomeRoute] = []
    private var relayCatDelegates: [String: RelayCatDelegate] = [:]

    func push(to route: HomeRoute) {
        path.append(route)
    }

    func push(to route: HomeRoute, relayCatDelegate: RelayCatDelegate) {
        if case let .relayCat(relayCat) = route {
            relayCatDelegates[relayCat.mediaId] = relayCatDelegate
        }
        path.append(route)
    }

    func relayCatDelegate(for mediaId: String) -> RelayCatDelegate? {
        relayCatDelegates[mediaId]
    }

    func pop() {
        _ = path.popLast()
    }
}
