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
    case updateCatProfileNotImplemented
    case deleteCatNotImplemented
}

public struct CatsClient: Sendable {
    public typealias UUID = String
    
    public let networkClient: NetworkClient?
    
    public var fetchCats: @Sendable (UUID) async throws -> [Cat]
    public var createCat: @Sendable (CreateCatRequestDTO) async throws -> Cat
    public var updateCatProfile: @Sendable (String, UpdateCatProfileRequestDTO) async throws -> Cat
    public var fetchCatFeed: @Sendable (UUID) async throws -> CatFeed
    public var deleteCat: @Sendable (String) async throws -> Void
    
    public init(
        networkClient: NetworkClient?,
        fetchCats: @escaping @Sendable (UUID) async throws -> [Cat],
        createCat: @escaping @Sendable (CreateCatRequestDTO) async throws -> Cat,
        updateCatProfile: @escaping @Sendable (String, UpdateCatProfileRequestDTO) async throws -> Cat,
        fetchCatFeed: @escaping @Sendable (UUID) async throws -> CatFeed,
        deleteCat: @escaping @Sendable (String) async throws -> Void
    ) {
        self.networkClient = networkClient
        self.fetchCats = fetchCats
        self.createCat = createCat
        self.updateCatProfile = updateCatProfile
        self.fetchCatFeed = fetchCatFeed
        self.deleteCat = deleteCat
    }
}
