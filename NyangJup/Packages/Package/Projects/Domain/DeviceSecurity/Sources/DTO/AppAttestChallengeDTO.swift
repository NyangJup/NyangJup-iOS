//
//  AppAttestChallengeDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

import DomainDeviceSecurityInterface

struct AppAttestChallengeRequest: Encodable, Sendable {
    let purpose: AppAttestPurpose
}

struct AppAttestChallengeResponse: Decodable, Sendable {
    let challengeId: String
    let challenge: String
    let expiresAt: String
}
