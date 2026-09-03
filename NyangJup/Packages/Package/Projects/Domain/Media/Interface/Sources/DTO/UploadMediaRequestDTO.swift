//
//  UploadMediaRequestDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct UploadMediaRequestDTO: Encodable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case catId
        case fileName
        case mediaType
        case place
        case comment
    }

    public let catId: String?
    public let fileName: String
    public let mediaType: String
    public let place: String?
    public let comment: String

    public init(
        catId: String?,
        fileName: String,
        mediaType: String,
        place: String?,
        comment: String
    ) {
        self.catId = catId
        self.fileName = fileName
        self.mediaType = mediaType
        self.place = place
        self.comment = comment
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(catId, forKey: .catId)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(mediaType, forKey: .mediaType)
        try container.encode(place, forKey: .place)
        try container.encode(comment, forKey: .comment)
    }
}
