import AVFAudio
import SwiftUI

import CoreCamera
import CoreNetwork
import CoreNetworkInterface
import CoreSecureStorage
import CoreSecureStorageInterface
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
import DomainCats
import DomainCatsInterface
import DomainMediaTesting
import DomainDeviceSecurity
import DomainDeviceSecurityInterface
import DomainProfile
import DomainProfileInterface
import DomainPixelReward
import DomainPixelRewardInterface

@main
struct HomeExampleApp: App {
    private let captureFactory: CaptureFactory
    private let catRegistrationFactory: CatRegistrationFactory
    private let imageLoaderClient: ImageLoaderClient
    private let relayCatFactory: RelayCatFactory
    private let nativeAdFactory: NativeAdFactory
    private let adsClient: AdsClient
    private let catsClient: CatsClient
    private let deviceSecurityClient: DeviceSecurityClient
    private let profileClient: ProfileClient
    private let pixelRewardClient: PixelRewardClient

    @State private var isAuthenticated = false
    @State private var authenticationFailed = false
    @State private var authenticationFailureMessage = ""

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)

        let imageLoaderClient = ImageLoaderClient.live()
        let adsClient = AdsClient.live
        let secureStorageClient = SecureStorageClient.live
        let networkClient = NetworkClient.live(
            secureStorageClient: secureStorageClient
        )

        let deviceSecurityClient = DeviceSecurityClient.live(
            networkClient: networkClient,
            secureStorageClient: secureStorageClient
        )
        let catsClient = CatsClient.live(
            networkClient: networkClient,
            deviceSecurityClient: deviceSecurityClient
        )

        self.captureFactory = CaptureFactory.live(
            cameraClient: .live,
            mediaClient: .test
        )
        self.catRegistrationFactory = CatRegistrationFactory.live(
            catsClient: catsClient,
            mediaClient: .test
        )
        self.imageLoaderClient = imageLoaderClient
        self.relayCatFactory = RelayCatFactory.live(
            mediaClient: .test,
            imageLoaderClient: imageLoaderClient,
            adsClient: adsClient
        )
        self.adsClient = adsClient
        self.catsClient = catsClient
        self.nativeAdFactory = .live
        self.deviceSecurityClient = deviceSecurityClient
        self.profileClient = ProfileClient.live(networkClient: networkClient)
        self.pixelRewardClient = PixelRewardClient.live(
            networkClient: networkClient,
            deviceSecurityClient: deviceSecurityClient
        )
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthenticated {
                    HomeRootView(
                        catsClient: catsClient,
                        profileClient: profileClient,
                        adsClient: adsClient,
                        pixelRewardClient: pixelRewardClient
                    )
                } else if authenticationFailed {
                    ContentUnavailableView(
                        "보안 인증에 실패했습니다.",
                        systemImage: "lock.slash",
                        description: Text(authenticationFailureMessage)
                    )
                }
            }
            .environment(\.captureFactory, captureFactory)
            .environment(\.catRegistrationFactory, catRegistrationFactory)
            .environment(\.imageLoaderClient, imageLoaderClient)
            .environment(\.relayCatFactory, relayCatFactory)
            .environment(\.nativeAdFactory, nativeAdFactory)
            .task {
                await adsClient.setup()
                do {
                    try await deviceSecurityClient.authenticate()
                    _ = try await profileClient.fetchProfile()
                    isAuthenticated = true
                } catch {
                    authenticationFailureMessage = authenticationErrorMessage(error)
                    authenticationFailed = true
                }
                
                
            }
        }
    }

    private func authenticationErrorMessage(_ error: Error) -> String {
        if let error = error as? NetworkError {
            switch error {
            case let .authorization(response),
                 let .badRequest(response),
                 let .notFound(response),
                 let .server(response),
                 let .client(response):
                return response.map { "\($0.code): \($0.message)" } ?? error.errorMessage
            default:
                return error.errorMessage
            }
        }

        return error.localizedDescription
    }
}
