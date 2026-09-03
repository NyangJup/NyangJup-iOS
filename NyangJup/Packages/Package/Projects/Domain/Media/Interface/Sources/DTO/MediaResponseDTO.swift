//
//  MediaResponseDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

import Foundation

import CoreNetworkInterface

public struct MediaResponseDTO: Decodable, Sendable {
    public let id: String
    public let catId: String?
    public let userId: String
    public let comment: String
    public let thumbnailURL: String?
    public let mediaType: String
    public let mediaURL: String?
    public let processingStatus: String

    public func toEntity() throws -> Media {
        guard let mediaType = MediaType(rawValue: mediaType),
              let processingStatus = ProcessingStatus(rawValue: processingStatus) else {
            throw NetworkError.decoding
        }

        return Media(
            id: id,
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
