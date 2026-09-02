//
//  CatFeedResponseDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

import Foundation

import CoreNetworkInterface
import DomainMediaInterface

public struct CatFeedResponseDTO: Decodable, Sendable {
    public let catId: String
    public let name: String
    public let place: String?
    public let thumbnailURL: String
    public let feed: [CatFeedMediaResponseDTO]
    public let nextCursor: String?

    public func toEntity() throws -> CatFeed {
        CatFeed(
            cat: Cat(
                id: catId,
                name: name,
                place: place,
                imageURL: thumbnailURL
            ),
            items: try feed.map { try $0.toEntity() },
            nextCursor: nextCursor
        )
    }
}

public struct CatFeedMediaResponseDTO: Decodable, Sendable {
    public let mediaId: String
    public let catId: String
    public let userId: String
    public let comment: String
    public let thumbnailURL: String
    public let mediaType: String
    public let mediaURL: String

    public func toEntity() throws -> Media {
        guard let mediaType = MediaType(rawValue: mediaType) else {
            throw NetworkError.decoding
        }

        return Media(
            id: mediaId,
            catId: catId,
            userId: userId,
            comment: comment,
            thumbnailURL: thumbnailURL,
            mediaType: mediaType,
            mediaURL: mediaURL
        )
    }
}
