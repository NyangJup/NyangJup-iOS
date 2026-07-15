import SwiftUI

import FeatureHome
import DomainProfileTesting
import DomainCatsTesting

@main
struct HomeExampleApp: App {
    var body: some Scene {
        WindowGroup {
            HomeRootView(
                catsClient: .test,
                profileClient: .test
            )
        }
    }
}
