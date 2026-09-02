//
//  CatsClient.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct CatsClient: Sendable {
    public var fetchCats: @Sendable () async throws -> [Cat]
    public var createCat: @Sendable (_ request: CreateCatRequestDTO) async throws -> Cat
    public var updateCatProfile: @Sendable (
        _ id: String,
        _ request: UpdateCatProfileRequestDTO
    ) async throws -> Cat
    public var fetchCatFeed: @Sendable (
        _ id: String,
        _ cursor: String?
    ) async throws -> CatFeed
    public var deleteCat: @Sendable (_ id: String) async throws -> Void
    public var fetchPixelCat: @Sendable (_ request: PixelCatRequestDTO) async throws -> PixelCat
    
    public init(
        fetchCats: @escaping @Sendable () async throws -> [Cat],
        createCat: @escaping @Sendable (_ request: CreateCatRequestDTO) async throws -> Cat,
        updateCatProfile: @escaping @Sendable (
            _ id: String,
            _ request: UpdateCatProfileRequestDTO
        ) async throws -> Cat,
        fetchCatFeed: @escaping @Sendable (
            _ id: String,
            _ cursor: String?
        ) async throws -> CatFeed,
        deleteCat: @escaping @Sendable (_ id: String) async throws -> Void,
        fetchPixelCat: @escaping @Sendable (_ request: PixelCatRequestDTO) async throws -> PixelCat
    ) {
        self.fetchCats = fetchCats
        self.createCat = createCat
        self.updateCatProfile = updateCatProfile
        self.fetchCatFeed = fetchCatFeed
        self.deleteCat = deleteCat
        self.fetchPixelCat = fetchPixelCat
    }
}
