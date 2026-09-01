import Foundation

import DomainPixelRewardInterface

public extension PixelRewardClient {
    static let test = Self(
        fetchBalance: {
            PixelRewardBalance(balance: 1)
        },
        createAdSession: {
            PixelRewardAdSession(
                sessionId: "test-session-id",
                expiresAt: Date(timeIntervalSince1970: 0)
            )
        },
        claimAdReward: { _ in
            PixelRewardBalance(balance: 2)
        }
    )
}
