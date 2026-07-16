//
//  HomeCoordinator.swift
//  NJPackage
//
//  Created by 정지훈 on 7/15/26.
//

import Foundation

import FeatureCommonInterface
import FeatureHomeInterface

@MainActor
@Observable
final class HomeCoordinator: Coordinator {
    typealias Route = HomeRoute

    var path: [HomeRoute] = []

    func push(to route: HomeRoute) {
        path.append(route)
    }

    func pop() {
        _ = path.popLast()
    }
}
