//
//  AppDependencies.swift
//  NyangJup
//
//  Created by 정지훈 on 9/11/26.
//

import CoreAds
import CoreAdsInterface
import CoreCamera
import CoreImageLoader
import CoreImageLoaderInterface
import CoreNetwork
import CoreNetworkInterface
import CoreSecureStorage
import CoreSecureStorageInterface
import CoreVideoClient
import CoreVideoInterface
import DomainCats
import DomainCatsInterface
import DomainDeviceSecurity
import DomainDeviceSecurityInterface
import DomainMedia
import DomainMediaInterface
import DomainPixelReward
import DomainPixelRewardInterface
import DomainProfile
import DomainProfileInterface
import FeatureCapture
import FeatureCaptureInterface
import FeatureCatRegistration
import FeatureCatRegistrationInterface
import FeatureRelayCat
import FeatureRelayCatInterface

@MainActor
struct AppDependencies {
    let captureFactory: CaptureFactory
    let catRegistrationFactory: CatRegistrationFactory
    let relayCatFactory: RelayCatFactory
    let nativeAdFactory: NativeAdFactory
    let imageLoaderClient: ImageLoaderClient

    let adsClient: AdsClient
    let catsClient: CatsClient
    let deviceSecurityClient: DeviceSecurityClient
    let mediaClient: MediaClient
    let profileClient: ProfileClient
    let pixelRewardClient: PixelRewardClient
    let videoTrimClient: VideoTrimClient

    static func live() -> Self {
        let secureStorageClient = SecureStorageClient.live
        let networkClient = NetworkClient.live(
            secureStorageClient: secureStorageClient
        )
        let imageLoaderClient = ImageLoaderClient.live()
        let adsClient = AdsClient.live
        let videoTrimClient = VideoTrimClient.live
        let deviceSecurityClient = DeviceSecurityClient.live(
            networkClient: networkClient,
            secureStorageClient: secureStorageClient
        )
        let catsClient = CatsClient.live(
            networkClient: networkClient,
            deviceSecurityClient: deviceSecurityClient
        )
        let mediaClient = MediaClient.live(networkClient: networkClient)
        let profileClient = ProfileClient.live(networkClient: networkClient)
        let pixelRewardClient = PixelRewardClient.live(
            networkClient: networkClient,
            deviceSecurityClient: deviceSecurityClient
        )

        return Self(
            captureFactory: CaptureFactory.live(
                cameraClient: .live,
                mediaClient: mediaClient,
                videoTrimClient: videoTrimClient
            ),
            catRegistrationFactory: CatRegistrationFactory.live(
                catsClient: catsClient,
                mediaClient: mediaClient
            ),
            relayCatFactory: RelayCatFactory.live(
                mediaClient: mediaClient,
                imageLoaderClient: imageLoaderClient,
                adsClient: adsClient
            ),
            nativeAdFactory: .live,
            imageLoaderClient: imageLoaderClient,
            adsClient: adsClient,
            catsClient: catsClient,
            deviceSecurityClient: deviceSecurityClient,
            mediaClient: mediaClient,
            profileClient: profileClient,
            pixelRewardClient: pixelRewardClient,
            videoTrimClient: videoTrimClient
        )
    }
}
