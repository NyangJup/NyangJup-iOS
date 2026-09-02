//
//  PixelRewardAdSession.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

import Foundation

public struct PixelRewardAdSession: Equatable, Sendable {
    public let sessionId: String
    public let expiresAt: Date

    public init(sessionId: String, expiresAt: Date) {
        self.sessionId = sessionId
        self.expiresAt = expiresAt
    }
}
