//
//  CatsClient.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

import CoreNetworkInterface

public struct CatsClient: Sendable {
    public typealias ID = Int64
    
    public let networkClient: NetworkClient?
    
    public var fetchCats: @Sendable (ID) async throws -> [Cat]
    public var fetchCatFeed: @Sendable (ID) async throws -> CatFeed
    
    public init(
        networkClient: NetworkClient?,
        fetchCats: @escaping @Sendable (ID) async throws -> [Cat],
        fetchCatFeed: @escaping @Sendable (ID) async throws -> CatFeed
    ) {
        self.networkClient = networkClient
        self.fetchCats = fetchCats
        self.fetchCatFeed = fetchCatFeed
    }
}
