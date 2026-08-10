//
//  AdsClient+Live.swift
//  NJPackage
//
//  Created by 정지훈 on 8/7/26.
//

import Foundation

import CoreAdsInterface
import GoogleMobileAds

public extension AdsClient {
    @MainActor
    static let live: AdsClient = {
        let rewardedAdsManager = RewardedAdsManager()
        let nativeAdsManager = NativeAdsManager()

        return AdsClient(
            setup: {
                await MobileAds.shared.start()
            },
            loadRewardAds: {
                try await rewardedAdsManager.loadAd()
            },
            showRewardAds: {
                try await rewardedAdsManager.showAd()
            },
            loadNativeAds: { count in
                await nativeAdsManager.loadAds(count: count)
            }
        )
    }()
}
