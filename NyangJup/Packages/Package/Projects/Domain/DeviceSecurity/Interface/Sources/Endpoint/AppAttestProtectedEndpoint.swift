//
//  AppAttestProtectedEndpoint.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

import Foundation

import CoreNetworkInterface

public struct AppAttestProtectedEndpoint<Base: Endpoint>: Endpoint {
    private let base: Base
    private let assertion: AppAttestAssertion

    public init(base: Base, assertion: AppAttestAssertion) {
        self.base = base
        self.assertion = assertion
    }

    public var baseURL: URL { base.baseURL }
    public var path: String { base.path }
    public var method: HTTPMethod { base.method }
    public var query: [URLQueryItem]? { base.query }
    public var body: Encodable? { base.body }
    public var requiresAuthorization: Bool { base.requiresAuthorization }

    public var headers: [String: String]? {
        var headers = base.headers ?? [:]
        headers["X-App-Attest-Key-Id"] = assertion.keyId
        headers["X-App-Attest-Challenge-Id"] = assertion.challengeId
        headers["X-App-Attest-Assertion"] = assertion.assertion
        return headers
    }
}
