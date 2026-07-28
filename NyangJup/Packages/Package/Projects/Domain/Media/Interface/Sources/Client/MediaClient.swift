//
//  MediaClient.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

import CoreNetworkInterface

public struct MediaClient: Sendable {
    public typealias ID = String
    public typealias Cursor = String
    
    public let networkClient: NetworkClient?
    
    public var fetchUploadURL: @Sendable (FetchUploadURLRequestDTO) async throws -> UploadURLResponseDTO
    public var uploadMedia: @Sendable (UploadMediaRequestDTO) async throws -> UploadMediaResponseDTO
    public var updateMedia: @Sendable (ID, UploadMediaRequestDTO) async throws -> UploadMediaResponseDTO
    public var fetchMedia: @Sendable (ID) async throws -> Media
    public var updateIsLiked: @Sendable (ID, Bool) async throws -> Void
    public var fetchRelayCats: @Sendable (FetchRelayCatsRequestDTO) async throws -> FetchRelayCatsResponseDTO
    public var deleteMedia: @Sendable (ID) async throws -> Media
    public var fetchFeeds: @Sendable (ID, Cursor?) async throws -> (FeedPage)
    
    public init(
        networkClient: NetworkClient?,
        fetchUploadURL: @escaping @Sendable (FetchUploadURLRequestDTO) async throws -> UploadURLResponseDTO,
        uploadMedia: @escaping @Sendable (UploadMediaRequestDTO) async throws -> UploadMediaResponseDTO,
        updateMedia: @escaping @Sendable (ID, UploadMediaRequestDTO) async throws -> UploadMediaResponseDTO,
        fetchMedia: @escaping @Sendable (ID) async throws -> Media,
        updateIsLiked: @escaping @Sendable (ID, Bool) async throws -> Void,
        fetchRelayCats: @escaping @Sendable (FetchRelayCatsRequestDTO) async throws -> FetchRelayCatsResponseDTO,
        deleteMedia: @escaping @Sendable (ID) async throws -> Media,
        fetchFeeds: @escaping @Sendable (ID, Cursor?) async throws -> FeedPage
    ) {
        self.networkClient = networkClient
        self.fetchUploadURL = fetchUploadURL
        self.uploadMedia = uploadMedia
        self.updateMedia = updateMedia
        self.fetchMedia = fetchMedia
        self.updateIsLiked = updateIsLiked
        self.fetchRelayCats = fetchRelayCats
        self.deleteMedia = deleteMedia
        self.fetchFeeds = fetchFeeds
    }
    
}
