//
//  AppAttestChallengeDecoder.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

import Foundation

import DomainDeviceSecurityInterface

enum AppAttestChallengeDecoder {
    static func decode(_ challenge: String) throws -> Data {
        let base64 = challenge
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padded = base64 + String(repeating: "=", count: (4 - base64.count % 4) % 4)

        guard let data = Data(base64Encoded: padded) else {
            throw DeviceSecurityError.invalidChallenge
        }
        return data
    }
}
