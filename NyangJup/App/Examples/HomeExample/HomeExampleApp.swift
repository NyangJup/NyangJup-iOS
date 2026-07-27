import SwiftUI

import CoreCamera
import CoreImageLoader
import CoreImageLoaderInterface
import FeatureCapture
import FeatureCaptureInterface
import FeatureHome
import FeatureRelayCat
import FeatureRelayCatInterface
import DomainMediaTesting
import DomainProfileTesting
import DomainCatsTesting

@main
struct HomeExampleApp: App {
    private let captureFactory: CaptureFactory
    private let imageLoaderClient: ImageLoaderClient
    private let relayCatFactory: RelayCatFactory

    init() {
        let imageLoaderClient = ImageLoaderClient.live()
        self.captureFactory = CaptureFactory.live(cameraClient: .live)
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
            .environment(\.captureFactory, captureFactory)
            .environment(\.imageLoaderClient, imageLoaderClient)
            .environment(\.relayCatFactory, relayCatFactory)
        }
    }
}
