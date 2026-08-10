//
//  AdsClient.swift
//  NJPackage
//
//  Created by 정지훈 on 8/7/26.
//


import Foundation
public struct AdsClient: Sendable {
    public typealias Count = Int

    public var setup: @Sendable () async -> Void
    public var loadRewardAds: @Sendable () async throws -> Void
    public var showRewardAds: @Sendable () async throws -> Bool
    public var loadNativeAds: @Sendable (Count) async throws -> [NativeAdItem]

    public init(
        setup: @Sendable @escaping () async -> Void,
        loadRewardAds: @Sendable @escaping () async throws -> Void,
        showRewardAds: @Sendable @escaping () async throws -> Bool,
        loadNativeAds: @Sendable @escaping (Count) async throws -> [NativeAdItem]
    ) {
        self.setup = setup
        self.loadRewardAds = loadRewardAds
        self.showRewardAds = showRewardAds
        self.loadNativeAds = loadNativeAds
    }
}
