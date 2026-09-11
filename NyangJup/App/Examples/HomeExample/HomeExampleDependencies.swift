//
//  HomeExampleDependencies.swift
//  NyangJup
//
//  Created by 정지훈 on 9/11/26.
//

import CoreAdsInterface
import CoreAdsTesting
import CoreImageLoaderInterface
import CoreImageLoaderTesting
import CoreVideoInterface
import CoreVideoTesting
import DomainCatsInterface
import DomainCatsTesting
import DomainMediaInterface
import DomainMediaTesting
import DomainPixelRewardInterface
import DomainPixelRewardTesting
import DomainProfileInterface
import DomainProfileTesting
import FeatureCaptureInterface
import FeatureCaptureTesting
import FeatureCatRegistrationInterface
import FeatureCatRegistrationTesting
import FeatureRelayCatInterface
import FeatureRelayCatTesting

@MainActor
struct HomeExampleDependencies {
    let captureFactory: CaptureFactory
    let catRegistrationFactory: CatRegistrationFactory
    let relayCatFactory: RelayCatFactory
    let nativeAdFactory: NativeAdFactory
    let imageLoaderClient: ImageLoaderClient

    let adsClient: AdsClient
    let catsClient: CatsClient
    let mediaClient: MediaClient
    let profileClient: ProfileClient
    let pixelRewardClient: PixelRewardClient
    let videoTrimClient: VideoTrimClient

    static func example() -> Self {
        Self(
            captureFactory: .test,
            catRegistrationFactory: .test,
            relayCatFactory: .test,
            nativeAdFactory: .test,
            imageLoaderClient: .test,
            adsClient: .test,
            catsClient: .test,
            mediaClient: .test,
            profileClient: .test,
            pixelRewardClient: .test,
            videoTrimClient: .test
        )
    }
}
