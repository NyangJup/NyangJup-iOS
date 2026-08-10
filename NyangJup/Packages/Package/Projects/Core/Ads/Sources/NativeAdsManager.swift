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
    private var continuation: CheckedContinuation<Void, Never>?

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

        await withCheckedContinuation { continuation in
            self.continuation = continuation
            loader.load(Request())
        }

        let ads = received
        received = []

        return ads.map { NativeAdItem(object: $0) }
    }

    private func finish() {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume()
    }
}

// MARK: - NativeAdLoaderDelegate

extension NativeAdsManager: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        received.append(nativeAd)
    }

    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        finish()
    }

    func adLoader(
        _ adLoader: AdLoader,
        didFailToReceiveAdWithError error: any Error
    ) {
        print("네이티브 광고 로드 실패:", error)
        finish()
    }
}
