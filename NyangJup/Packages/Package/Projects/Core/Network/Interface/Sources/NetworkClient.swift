//
//  File.swift
//  NJPackage
//
//  Created by 정지훈 on 7/1/26.
//

import Foundation

public protocol NetworkClientProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: any Endpoint) async throws -> T
}

public struct NetworkClient: Sendable {
    private let provider: any NetworkClientProtocol

    public init(provider: any NetworkClientProtocol) {
        self.provider = provider
    }

    public func request<T: Decodable>(_ endpoint: any Endpoint) async throws -> T {
        try await provider.request(endpoint)
    }
}
