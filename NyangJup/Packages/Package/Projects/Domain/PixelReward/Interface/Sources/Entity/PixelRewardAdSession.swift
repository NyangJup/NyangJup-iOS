import Foundation

public struct PixelRewardAdSession: Equatable, Sendable {
    public let sessionId: String
    public let expiresAt: Date

    public init(sessionId: String, expiresAt: Date) {
        self.sessionId = sessionId
        self.expiresAt = expiresAt
    }
}
