//
//  MediaClient.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct MediaClient: Sendable {
    public var fetchUploadURL: @Sendable (_ request: FetchUploadURLRequestDTO) async throws -> UploadURL
    public var uploadToPresignedURL: @Sendable (
        _ uploadURL: UploadURL,
        _ source: PresignedUploadSource,
        _ mediaType: MediaType
    ) async throws -> Void
    public var registerMedia: @Sendable (_ request: UploadMediaRequestDTO) async throws -> Media
    public var uploadVideo: @Sendable (_ upload: PreparedVideoUpload) async throws -> Media
    public var updateMedia: @Sendable (
        _ id: String,
        _ request: UploadMediaRequestDTO
    ) async throws -> Media
    public var updateComment: @Sendable (_ id: String, _ comment: String) async throws -> Media
    public var fetchMedia: @Sendable (_ id: String) async throws -> Media
    public var updateIsLiked: @Sendable (
        _ id: String,
        _ isLiked: Bool
    ) async throws -> Void
    public var fetchRelayCats: @Sendable (_ request: FetchRelayCatsRequestDTO) async throws -> RelayPage
    public var deleteMedia: @Sendable (_ id: String) async throws -> Media
    
    public init(
        fetchUploadURL: @escaping @Sendable (_ request: FetchUploadURLRequestDTO) async throws -> UploadURL,
        uploadToPresignedURL: @escaping @Sendable (
            _ uploadURL: UploadURL,
            _ source: PresignedUploadSource,
        _ mediaType: MediaType
        ) async throws -> Void,
        registerMedia: @escaping @Sendable (_ request: UploadMediaRequestDTO) async throws -> Media,
        uploadVideo: @escaping @Sendable (_ upload: PreparedVideoUpload) async throws -> Media,
        updateMedia: @escaping @Sendable (
            _ id: String,
            _ request: UploadMediaRequestDTO
        ) async throws -> Media,
        updateComment: @escaping @Sendable (_ id: String, _ comment: String) async throws -> Media,
        fetchMedia: @escaping @Sendable (_ id: String) async throws -> Media,
        updateIsLiked: @escaping @Sendable (
            _ id: String,
            _ isLiked: Bool
        ) async throws -> Void,
        fetchRelayCats: @escaping @Sendable (_ request: FetchRelayCatsRequestDTO) async throws -> RelayPage,
        deleteMedia: @escaping @Sendable (_ id: String) async throws -> Media
    ) {
        self.fetchUploadURL = fetchUploadURL
        self.uploadToPresignedURL = uploadToPresignedURL
        self.registerMedia = registerMedia
        self.uploadVideo = uploadVideo
        self.updateMedia = updateMedia
        self.updateComment = updateComment
        self.fetchMedia = fetchMedia
        self.updateIsLiked = updateIsLiked
        self.fetchRelayCats = fetchRelayCats
        self.deleteMedia = deleteMedia
    }
    
}
