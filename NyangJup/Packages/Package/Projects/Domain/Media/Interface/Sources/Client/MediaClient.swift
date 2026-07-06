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
    
    public let networkClient: NetworkClient?
    
    public var fetchUploadURL: @Sendable (ID) async throws -> UploadURLResponseDTO
    public var uploadMedia: @Sendable (UploadMediaRequestDTO) async throws -> Void
    public var updateMedia: @Sendable (UploadMediaRequestDTO) async throws -> Void
    public var fetchMedia: @Sendable (ID) async throws -> Media
    public var deleteMedia: @Sendable (ID) async throws -> Media
    
    public init(
        networkClient: NetworkClient?,
        fetchUploadURL: @escaping @Sendable (ID) async throws -> UploadURLResponseDTO,
        uploadMedia: @escaping @Sendable (UploadMediaRequestDTO) async throws -> Void,
        updateMedia: @escaping @Sendable (UploadMediaRequestDTO) async throws -> Void,
        fetchMedia: @escaping @Sendable (ID) async throws -> Media,
        deleteMedia: @escaping @Sendable (ID) async throws -> Media
    ) {
        self.networkClient = networkClient
        self.fetchUploadURL = fetchUploadURL
        self.uploadMedia = uploadMedia
        self.updateMedia = updateMedia
        self.fetchMedia = fetchMedia
        self.deleteMedia = deleteMedia
    }
    
}
