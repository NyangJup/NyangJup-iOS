import SwiftUI

import CoreCamera
import CoreImageLoader
import CoreImageLoaderInterface
import CoreAds
import CoreAdsInterface
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
    private let nativeAdFactory: NativeAdFactory
    private let adsClient: AdsClient

    init() {
        let imageLoaderClient = ImageLoaderClient.live()
        let adsClient = AdsClient.live

        self.captureFactory = CaptureFactory.live(
            cameraClient: .live,
            mediaClient: .test
        )
        self.imageLoaderClient = imageLoaderClient
        self.relayCatFactory = RelayCatFactory.live(
            mediaClient: .test,
            imageLoaderClient: imageLoaderClient,
            adsClient: adsClient
        )
        self.adsClient = adsClient
        self.nativeAdFactory = .live
    }

    var body: some Scene {
        WindowGroup {
            HomeRootView(
                catsClient: .test,
                profileClient: .test,
                mediaClient: .test,
                adsClient: adsClient
            )
            .environment(\.captureFactory, captureFactory)
            .environment(\.imageLoaderClient, imageLoaderClient)
            .environment(\.relayCatFactory, relayCatFactory)
            .environment(\.nativeAdFactory, nativeAdFactory)
            .task {
                await adsClient.setup()
            }
        }
    }
}
