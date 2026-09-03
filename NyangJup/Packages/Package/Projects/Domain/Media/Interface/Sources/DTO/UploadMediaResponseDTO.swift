//
//  UploadMediaResponseDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

import CoreNetworkInterface

public struct UploadMediaResponseDTO: Decodable, Sendable {
    public let catId: String?
    public let mediaId: String
    public let userId: String
    public let mediaType: String
    public let processingStatus: String
    public let mediaURL: String?
    public let thumbnailURL: String?
    public let comment: String

    public init(
        catId: String?,
        mediaId: String,
        userId: String,
        mediaType: String,
        processingStatus: String,
        mediaURL: String?,
        thumbnailURL: String?,
        comment: String
    ) {
        self.catId = catId
        self.mediaId = mediaId
        self.userId = userId
        self.mediaType = mediaType
        self.processingStatus = processingStatus
        self.mediaURL = mediaURL
        self.thumbnailURL = thumbnailURL
        self.comment = comment
    }

    public func toEntity() throws -> Media {
        guard let mediaType = MediaType(rawValue: mediaType),
              let processingStatus = ProcessingStatus(rawValue: processingStatus) else {
            throw NetworkError.decoding
        }

        return Media(
            id: mediaId,
            catId: catId,
            userId: userId,
            comment: comment,
            thumbnailURL: thumbnailURL,
            mediaType: mediaType,
            mediaURL: mediaURL,
            processingStatus: processingStatus
        )
    }
}
