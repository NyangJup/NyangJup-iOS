//
//  PixelRewardClient.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

public struct PixelRewardClient: Sendable {
    public var fetchBalance: @Sendable () async throws -> PixelRewardBalance
    public var createAdSession: @Sendable () async throws -> PixelRewardAdSession
    public var claimAdReward: @Sendable (_ sessionId: String) async throws -> PixelRewardBalance

    public init(
        fetchBalance: @escaping @Sendable () async throws -> PixelRewardBalance,
        createAdSession: @escaping @Sendable () async throws -> PixelRewardAdSession,
        claimAdReward: @escaping @Sendable (_: String) async throws -> PixelRewardBalance
    ) {
        self.fetchBalance = fetchBalance
        self.createAdSession = createAdSession
        self.claimAdReward = claimAdReward
    }
}
