import SwiftUI

import FeatureHome
import FeatureHomeInterface
import DomainProfileTesting
import DomainCatsTesting

@main
struct HomeExampleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView(
                    viewModel: HomeViewModel(
                        catsClient: .test,
                        profileClient: .test
                    )
                )
            }
        }
    }
}
