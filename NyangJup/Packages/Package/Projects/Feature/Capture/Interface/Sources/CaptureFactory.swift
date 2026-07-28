import SwiftUI

import DomainCatsInterface
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
    public let cat: Cat?
    
    public init(
        showsModePicker: Bool,
        cat: Cat? = nil
    ) {
        self.showsModePicker = showsModePicker
        self.cat = cat
    }
}
