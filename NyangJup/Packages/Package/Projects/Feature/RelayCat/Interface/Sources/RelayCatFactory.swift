//
//  RelayCatFactory.swift
//  NJPackage
//
//  Created by 정지훈 on 7/22/26.
//

import SwiftUI

import DomainMediaInterface
import FeatureCommonInterface

public struct RelayCatFactory: Factorable, Sendable {
    public var makeView: @MainActor @Sendable (FeatureConfiguration?, FeatureDelegate?) -> AnyView

    public init(
        makeView: @escaping @MainActor @Sendable (FeatureConfiguration?, FeatureDelegate?) -> AnyView
    ) {
        self.makeView = makeView
    }
}

public struct RelayCatConfiguration: FeatureConfiguration {
    public let relayCat: RelayCat

    public init(
        relayCat: RelayCat
    ) {
        self.relayCat = relayCat
    }
}
