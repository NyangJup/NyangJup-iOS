//
//  Media.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct Media: Sendable {
    public let id: String
    public let catId: String
    public let userId: String
    public let comment: String
    public let thumbnailURL: String
    public let mediaType: MediaType
    public let mediaURL: String
    
    public init(
        id: String,
        catId: String,
        userId: String,
        comment: String,
        thumbnailURL: String,
        mediaType: MediaType,
        mediaURL: String
    ) {
        self.id = id
        self.catId = catId
        self.userId = userId
        self.comment = comment
        self.thumbnailURL = thumbnailURL
        self.mediaType = mediaType
        self.mediaURL = mediaURL
    }
}
