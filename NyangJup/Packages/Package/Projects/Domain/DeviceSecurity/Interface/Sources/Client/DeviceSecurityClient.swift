//
//  DeviceSecurityClient.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

import CoreNetworkInterface

public struct DeviceSecurityClient: Sendable {
    public var authenticate: @Sendable () async throws -> Void
    public var generateAssertion: @Sendable (
        _ purpose: AppAttestPurpose,
        _ endpoint: any Endpoint
    ) async throws -> AppAttestAssertion

    public init(
        authenticate: @escaping @Sendable () async throws -> Void,
        generateAssertion: @escaping @Sendable (
            _: AppAttestPurpose,
            _: any Endpoint
        ) async throws -> AppAttestAssertion
    ) {
        self.authenticate = authenticate
        self.generateAssertion = generateAssertion
    }
}
