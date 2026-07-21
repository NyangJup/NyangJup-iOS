import SwiftUI

import FeatureHome
import DomainMediaTesting
import DomainProfileTesting
import DomainCatsTesting

@main
struct HomeExampleApp: App {
    var body: some Scene {
        WindowGroup {
            HomeRootView(
                catsClient: .test,
                profileClient: .test,
                mediaClient: .test
            )
        }
    }
}
