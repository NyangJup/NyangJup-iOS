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

public extension CatRegistrationFactory {
    static let unimplemented = Self { _, _ in
        assertionFailure("CatRegistrationFactory가 Environment에 주입되지 않았습니다.")
        return AnyView(EmptyView())
    }
}

public extension EnvironmentValues {
    @Entry var catRegistrationFactory = CatRegistrationFactory.unimplemented
}
