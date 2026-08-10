//
//  NativeAdsManager.swift
//  NJPackage
//
//  Created by 정지훈 on 8/7/26.
//
import UIKit

import CoreAdsInterface
import GoogleMobileAds

@MainActor
final class NativeAdsManager: NSObject {
    private var adLoader: AdLoader?
    private var received: [NativeAd] = []
    private var continuation: CheckedContinuation<[NativeAdItem], Never>?

    func loadAds(count: Int) async -> [NativeAdItem] {
        guard continuation == nil else { return [] }

        let options = MultipleAdsAdLoaderOptions()
        options.numberOfAds = min(max(count, 1), 5)

        let loader = AdLoader(
            adUnitID: AdsType.native.adsId,
            rootViewController: nil,
            adTypes: [.native],
            options: [options]
        )
        loader.delegate = self
        adLoader = loader
        received = []

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            loader.load(Request())
        }
    }

    private func finish(for adLoader: AdLoader) {
        guard adLoader === self.adLoader, let continuation else { return }
        let ads = received.map { NativeAdItem(object: $0) }

        self.adLoader = nil
        received = []
        self.continuation = nil
        continuation.resume(returning: ads)
    }
}

// MARK: - NativeAdLoaderDelegate

extension NativeAdsManager: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        guard adLoader === self.adLoader else { return }
        received.append(nativeAd)
    }

    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        finish(for: adLoader)
    }

    func adLoader(
        _ adLoader: AdLoader,
        didFailToReceiveAdWithError error: any Error
    ) {
        guard adLoader === self.adLoader else { return }
        print("네이티브 광고 로드 실패:", error)
    }
}
