import SwiftUI

import FeatureCommonInterface

public struct CaptureFactory: Factorable, Sendable {
    public var makeView: @MainActor @Sendable (FeatureConfiguration?, FeatureDelegate?) -> AnyView

    public init(
        makeView: @escaping @MainActor @Sendable (FeatureConfiguration?, FeatureDelegate?) -> AnyView,
    ) {
        self.makeView = makeView
    }
}

public struct CaptureConfiguration: FeatureConfiguration {
    public let showsModePicker: Bool
    
    public init(
        showsModePicker: Bool
    ) {
        self.showsModePicker = showsModePicker
    }
}
