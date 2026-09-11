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

public extension RelayCatFactory {
    static let unimplemented = Self { _, _ in
        assertionFailure("RelayCatFactory가 Environment에 주입되지 않았습니다.")
        return AnyView(EmptyView())
    }
}

public extension EnvironmentValues {
    @Entry var relayCatFactory = RelayCatFactory.unimplemented
}

public struct RelayCatConfiguration: FeatureConfiguration {
    public let relayCat: RelayCat

    public init(
        relayCat: RelayCat
    ) {
        self.relayCat = relayCat
    }
}
