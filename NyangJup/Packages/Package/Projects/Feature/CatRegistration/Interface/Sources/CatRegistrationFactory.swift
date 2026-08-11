import SwiftUI

import FeatureCommonInterface

public struct CatRegistrationFactory: Factorable, Sendable {
    public var makeView: @MainActor @Sendable (
        FeatureConfiguration?,
        FeatureDelegate?
    ) -> AnyView

    public init(
        makeView: @escaping @MainActor @Sendable (
            FeatureConfiguration?,
            FeatureDelegate?
        ) -> AnyView
    ) {
        self.makeView = makeView
    }
}

private struct CatRegistrationFactoryKey: EnvironmentKey {
    static let defaultValue = CatRegistrationFactory { _, _ in
        AnyView(EmptyView())
    }
}

public extension EnvironmentValues {
    var catRegistrationFactory: CatRegistrationFactory {
        get { self[CatRegistrationFactoryKey.self] }
        set { self[CatRegistrationFactoryKey.self] = newValue }
    }
}
