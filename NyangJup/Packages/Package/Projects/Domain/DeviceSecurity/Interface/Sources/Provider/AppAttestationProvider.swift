//
//  AppAttestationProvider.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

import Foundation

public struct AppAttestationProvider: Sendable {
    public var isSupported: @Sendable () -> Bool
    public var generateKey: @Sendable () async throws -> String
    public var attestKey: @Sendable (_ keyId: String, _ clientDataHash: Data) async throws -> Data
    public var generateAssertion: @Sendable (_ keyId: String, _ clientDataHash: Data) async throws -> Data

    public init(
        isSupported: @escaping @Sendable () -> Bool,
        generateKey: @escaping @Sendable () async throws -> String,
        attestKey: @escaping @Sendable (_: String, _: Data) async throws -> Data,
        generateAssertion: @escaping @Sendable (_: String, _: Data) async throws -> Data
    ) {
        self.isSupported = isSupported
        self.generateKey = generateKey
        self.attestKey = attestKey
        self.generateAssertion = generateAssertion
    }
}
