//
//  RewardedAdsManager.swift
//  NJPackage
//
//  Created by 정지훈 on 8/7/26.
//

import CoreAdsInterface
import GoogleMobileAds

@MainActor
final class RewardedAdsManager: NSObject {
    private var rewardedAd: RewardedAd?
    private var continuation: CheckedContinuation<Bool, Never>?
    private var didEarnReward = false

    func loadAd() async throws {
        do {
            rewardedAd = try await RewardedAd
                .load(
                    with: AdsType.reward.adsId,
                    request: Request()
                )
            rewardedAd?.fullScreenContentDelegate = self
        } catch {
            throw error
        }
    }

    func showAd() async throws -> Bool {
        guard let rewardedAd else {
            throw AdsError.adNotReady
        }

        didEarnReward = false

        return await withCheckedContinuation { continuation in
            self.continuation = continuation

            rewardedAd.present(from: nil) { [weak self] in
                // 보상 획득 "기록"만 한다.
                // 흐름 재개는 광고가 완전히 닫힌 뒤에.
                self?.didEarnReward = true
            }
        }
    }

    /// 중복 resume(크래시)과 미재개(먹통)를 한 곳에서 막는다.
    private func finish(with earned: Bool) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(returning: earned)
    }
}

// MARK: - GADFullScreenContentDelegate methods
extension RewardedAdsManager: FullScreenContentDelegate {
    // [START ad_events]
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        print("\(#function) called", error)
        rewardedAd = nil

        // 표시에 실패하면 보상 핸들러는 호출되지 않는다.
        // 여기서 풀어주지 않으면 showAd()가 영영 대기한다.
        finish(with: false)
        didEarnReward = false

        // 표시 실패 후에도 다음 요청을 처리할 수 있도록 새 광고를 미리 로드한다.
        Task { try? await loadAd() }
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
        // Clear the rewarded ad.
        rewardedAd = nil

        // 광고가 완전히 닫힌 뒤에 흐름을 재개해야
        // 다음 화면(sheet)이 정상적으로 올라온다.
        finish(with: didEarnReward)
        didEarnReward = false

        // 보상형 광고는 1회용이므로 다음 광고를 미리 로드한다.
        Task { try? await loadAd() }
    }

}
