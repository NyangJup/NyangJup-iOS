import SwiftUI

import CoreCamera
import FeatureCapture
import FeatureHome
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
                .environment(\.captureFactory, .live(cameraClient: .live))
            }
        }
    }
}
