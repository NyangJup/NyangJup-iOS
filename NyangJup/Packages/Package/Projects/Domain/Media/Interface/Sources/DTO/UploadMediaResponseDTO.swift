//
//  UploadMediaResponseDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct UploadMediaResponseDTO: Decodable, Sendable {
    public let catId: String?
    public let mediaId: String
    public let userId: String
    public let mediaType: String
    public let mediaURL: String
    public let thumbnailURL: String
    public let comment: String

    public init(
        catId: String?,
        mediaId: String,
        userId: String,
        mediaType: String,
        mediaURL: String,
        thumbnailURL: String,
        comment: String
    ) {
        self.catId = catId
        self.mediaId = mediaId
        self.userId = userId
        self.mediaType = mediaType
        self.mediaURL = mediaURL
        self.thumbnailURL = thumbnailURL
        self.comment = comment
    }
}
