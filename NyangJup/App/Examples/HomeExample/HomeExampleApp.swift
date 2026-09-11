import SwiftUI

import FeatureHome

@main
struct HomeExampleApp: App {
    private let dependencies = HomeExampleDependencies.example()

    var body: some Scene {
        WindowGroup {
            HomeRootView(
                catsClient: dependencies.catsClient,
                mediaClient: dependencies.mediaClient,
                videoTrimClient: dependencies.videoTrimClient,
                profileClient: dependencies.profileClient,
                adsClient: dependencies.adsClient,
                pixelRewardClient: dependencies.pixelRewardClient
            )
            .environment(\.captureFactory, dependencies.captureFactory)
            .environment(\.catRegistrationFactory, dependencies.catRegistrationFactory)
            .environment(\.imageLoaderClient, dependencies.imageLoaderClient)
            .environment(\.relayCatFactory, dependencies.relayCatFactory)
            .environment(\.nativeAdFactory, dependencies.nativeAdFactory)
        }
    }
}
