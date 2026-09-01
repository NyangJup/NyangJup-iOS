//
//  AppAttestPurpose.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

public enum AppAttestPurpose: String, Encodable, Equatable, Sendable {
    case attestation = "ATTESTATION"
    case adSession = "AD_SESSION"
    case adReward = "AD_REWARD"
}
