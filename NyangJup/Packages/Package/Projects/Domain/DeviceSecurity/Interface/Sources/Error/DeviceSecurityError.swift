//
//  DeviceSecurityError.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

public enum DeviceSecurityError: Error, Equatable, Sendable {
    case appAttestUnsupported
    case invalidAppAttestKey
    case invalidChallenge
}
