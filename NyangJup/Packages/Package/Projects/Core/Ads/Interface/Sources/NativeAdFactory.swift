//
//  File.swift
//  NJPackage
//
//  Created by 정지훈 on 8/7/26.
//

import SwiftUI

public struct NativeAdFactory: Sendable {
    public var makeView: @MainActor @Sendable (NativeAdItem) -> AnyView

    public init(
        makeView: @escaping @MainActor @Sendable (NativeAdItem) -> AnyView
    ) {
        self.makeView = makeView
    }
}

private struct NativeAdFactoryKey: EnvironmentKey {
    static let defaultValue = NativeAdFactory { _ in
        AnyView(EmptyView())
    }
}

public extension EnvironmentValues {
    var nativeAdFactory: NativeAdFactory {
        get { self[NativeAdFactoryKey.self] }
        set { self[NativeAdFactoryKey.self] = newValue }
    }
}
