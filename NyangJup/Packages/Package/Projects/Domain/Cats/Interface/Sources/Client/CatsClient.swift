//
//  CatsClient.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

import CoreNetworkInterface

public enum CatsClientError: Error {
    case createCatNotImplemented
}

public struct CatsClient: Sendable {
    public typealias UUID = String
    
    public let networkClient: NetworkClient?
    
    public var fetchCats: @Sendable (UUID) async throws -> [Cat]
    public var createCat: @Sendable (CreateCatRequestDTO) async throws -> Cat
    public var fetchCatFeed: @Sendable (UUID) async throws -> CatFeed
    
    public init(
        networkClient: NetworkClient?,
        fetchCats: @escaping @Sendable (UUID) async throws -> [Cat],
        createCat: @escaping @Sendable (CreateCatRequestDTO) async throws -> Cat,
        fetchCatFeed: @escaping @Sendable (UUID) async throws -> CatFeed
    ) {
        self.networkClient = networkClient
        self.fetchCats = fetchCats
        self.createCat = createCat
        self.fetchCatFeed = fetchCatFeed
    }
}
