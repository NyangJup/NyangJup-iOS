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

public extension NativeAdFactory {
    static let unimplemented = Self { _ in
        assertionFailure("NativeAdFactory가 Environment에 주입되지 않았습니다.")
        return AnyView(EmptyView())
    }
}

public extension EnvironmentValues {
    @Entry var nativeAdFactory = NativeAdFactory.unimplemented
}
