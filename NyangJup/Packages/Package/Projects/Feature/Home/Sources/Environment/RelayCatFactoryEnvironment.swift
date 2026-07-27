//
//  RelayCatFactoryEnvironment.swift
//  NJPackage
//
//  Created by 정지훈 on 7/22/26.
//

import SwiftUI

import FeatureRelayCatInterface

private struct RelayCatFactoryKey: EnvironmentKey {
    static let defaultValue = RelayCatFactory { _, _ in
        AnyView(EmptyView())
    }
}

public extension EnvironmentValues {
    var relayCatFactory: RelayCatFactory {
        get { self[RelayCatFactoryKey.self] }
        set { self[RelayCatFactoryKey.self] = newValue }
    }
}
