//
//  AppAttestAssertion.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

public struct AppAttestAssertion: Sendable, Equatable {
    public let keyId: String
    public let challengeId: String
    public let assertion: String

    public init(keyId: String, challengeId: String, assertion: String) {
        self.keyId = keyId
        self.challengeId = challengeId
        self.assertion = assertion
    }
}
