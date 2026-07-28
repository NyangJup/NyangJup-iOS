//
//  RelayCat.swift
//  NJPackage
//
//  Created by 정지훈 on 7/22/26.
//

public struct RelayCat: Hashable, Sendable {
    public let mediaId: String
    public let catId: String
    public let userId: String
    public let comment: String
    public let thumbnailURL: String
    public let name: String
    public let mediaType: MediaType
    public let mediaURL: String
    public var isLiked: Bool

    public init(
        mediaId: String,
        catId: String,
        userId: String,
        comment: String,
        thumbnailURL: String,
        name: String,
        mediaType: MediaType,
        mediaURL: String,
        isLiked: Bool
    ) {
        self.mediaId = mediaId
        self.catId = catId
        self.userId = userId
        self.comment = comment
        self.thumbnailURL = thumbnailURL
        self.name = name
        self.mediaType = mediaType
        self.mediaURL = mediaURL
        self.isLiked = isLiked
    }
}
