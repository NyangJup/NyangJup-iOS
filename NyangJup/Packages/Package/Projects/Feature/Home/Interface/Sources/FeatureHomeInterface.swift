import SwiftUI

import FeatureCommonInterface

public struct HomeFactory: Factorable {
    public var makeView: () -> AnyView
    public var makeViewModel: () -> any NZViewModel
    
    public init(
        makeView: @escaping () -> AnyView,
        makeViewModel: @escaping () -> any NZViewModel
    ) {
        self.makeView = makeView
        self.makeViewModel = makeViewModel
    }
}
