//
//  FetchRelayCatsResponseDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/22/26.
//

import Foundation

import CoreNetworkInterface

public struct FetchRelayCatsResponseDTO: Decodable, Sendable {
    public let items: [RelayCatResponseDTO]
    public let anchorIndex: Int
    public let previousCursor: String?
    public let nextCursor: String?

    public init(
        items: [RelayCatResponseDTO],
        anchorIndex: Int,
        previousCursor: String?,
        nextCursor: String?
    ) {
        self.items = items
        self.anchorIndex = anchorIndex
        self.previousCursor = previousCursor
        self.nextCursor = nextCursor
    }

    public func toEntity() throws -> RelayPage {
        RelayPage(
            items: try items.map { try $0.toEntity() },
            anchorIndex: anchorIndex,
            previousCursor: previousCursor,
            nextCursor: nextCursor
        )
    }
}

public struct RelayCatResponseDTO: Decodable, Sendable {
    public let mediaId: String
    public let catId: String
    public let userId: String
    public let comment: String
    public let place: String?
    public let thumbnailURL: String
    public let name: String
    public let catImageURL: String
    public let mediaType: String
    public let mediaURL: String
    public let isLiked: Bool

    public func toEntity() throws -> RelayCat {
        guard let mediaType = MediaType(rawValue: mediaType) else {
            throw NetworkError.decoding
        }

        return RelayCat(
            mediaId: mediaId,
            catId: catId,
            userId: userId,
            comment: comment,
            place: place,
            thumbnailURL: thumbnailURL,
            name: name,
            catImageURL: catImageURL,
            mediaType: mediaType,
            mediaURL: mediaURL,
            isLiked: isLiked
        )
    }
}
