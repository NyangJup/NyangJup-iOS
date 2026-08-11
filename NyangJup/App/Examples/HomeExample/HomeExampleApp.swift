import AVFAudio
import SwiftUI

import CoreCamera
import CoreImageLoader
import CoreImageLoaderInterface
import CoreAds
import CoreAdsInterface
import FeatureCapture
import FeatureCaptureInterface
import FeatureCatRegistration
import FeatureCatRegistrationInterface
import FeatureHome
import FeatureRelayCat
import FeatureRelayCatInterface
import DomainMediaTesting
import DomainProfileTesting
import DomainCatsTesting

@main
struct HomeExampleApp: App {
    private let captureFactory: CaptureFactory
    private let catRegistrationFactory: CatRegistrationFactory
    private let imageLoaderClient: ImageLoaderClient
    private let relayCatFactory: RelayCatFactory
    private let nativeAdFactory: NativeAdFactory
    private let adsClient: AdsClient

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)

        let imageLoaderClient = ImageLoaderClient.live()
        let adsClient = AdsClient.live

        self.captureFactory = CaptureFactory.live(
            cameraClient: .live,
            mediaClient: .test
        )
        self.catRegistrationFactory = CatRegistrationFactory.live(
            catsClient: .test,
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
            .environment(\.catRegistrationFactory, catRegistrationFactory)
            .environment(\.imageLoaderClient, imageLoaderClient)
            .environment(\.relayCatFactory, relayCatFactory)
            .environment(\.nativeAdFactory, nativeAdFactory)
            .task {
                await adsClient.setup()
            }
        }
    }
}
