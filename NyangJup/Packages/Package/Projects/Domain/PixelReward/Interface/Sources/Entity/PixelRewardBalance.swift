//
//  PixelRewardBalance.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

public struct PixelRewardBalance: Equatable, Sendable {
    public let balance: Int64

    public init(balance: Int64) {
        self.balance = balance
    }
}
