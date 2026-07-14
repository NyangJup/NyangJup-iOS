//
//  CaptureCoordinator.swift
//  NJPackage
//
//  Created by 정지훈 on 7/13/26.
//

import Foundation

import FeatureCommonInterface
import FeatureCaptureInterface

@MainActor
@Observable
final class CaptureCoordinator: Coordinator {
    typealias Route = CaptureRoute

    var path: [CaptureRoute] = []

    func push(to route: CaptureRoute) {
        path.append(route)
    }

    func pop() {
        _ = path.popLast()
    }
}
