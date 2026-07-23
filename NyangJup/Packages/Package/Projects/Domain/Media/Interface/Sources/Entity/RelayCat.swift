//
//  RelayCat.swift
//  NJPackage
//
//  Created by 정지훈 on 7/22/26.
//

public struct RelayCat: Hashable, Sendable {
    public let id: String
    public let memo: String
    public let thumbnailURL: String
    public let name: String
    public let mediaType: MediaType
    public let mediaURL: String
    public var isLiked: Bool

    public init(
        id: String,
        memo: String,
        thumbnailURL: String,
        name: String,
        mediaType: MediaType,
        mediaURL: String,
        isLiked: Bool
    ) {
        self.id = id
        self.memo = memo
        self.thumbnailURL = thumbnailURL
        self.name = name
        self.mediaType = mediaType
        self.mediaURL = mediaURL
        self.isLiked = isLiked
    }
}
