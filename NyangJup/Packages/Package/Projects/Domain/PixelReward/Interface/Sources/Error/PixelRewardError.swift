//
//  PixelRewardError.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

public enum PixelRewardError: Error, Equatable, Sendable {
    case sessionUnavailable
    case sessionNotFound
    case appAttestReplay
    case invalidChallenge
}
