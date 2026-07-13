import SwiftUI

import FeatureCommonInterface

public struct HomeFactory: Factorable, Sendable {
    public var makeView: @MainActor @Sendable (FeatureConfiguration?, FeatureDelegate?) -> AnyView
    
    public init(
        makeView: @escaping @MainActor @Sendable (FeatureConfiguration?, FeatureDelegate?) -> AnyView
    ) {
        self.makeView = makeView
    }
}
