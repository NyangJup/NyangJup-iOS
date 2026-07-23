import SwiftUI

import CoreImageLoader
import CoreImageLoaderInterface
import FeatureHome
import FeatureRelayCat
import FeatureRelayCatInterface
import DomainMediaTesting
import DomainProfileTesting
import DomainCatsTesting

@main
struct HomeExampleApp: App {
    private let imageLoaderClient: ImageLoaderClient
    private let relayCatFactory: RelayCatFactory

    init() {
        let imageLoaderClient = ImageLoaderClient.live()
        self.imageLoaderClient = imageLoaderClient
        self.relayCatFactory = RelayCatFactory.live(
            mediaClient: .test,
            imageLoaderClient: imageLoaderClient
        )
    }

    var body: some Scene {
        WindowGroup {
            HomeRootView(
                catsClient: .test,
                profileClient: .test,
                mediaClient: .test
            )
            .environment(\.imageLoaderClient, imageLoaderClient)
            .environment(\.relayCatFactory, relayCatFactory)
        }
    }
}
