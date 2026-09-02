//
//  FetchUploadURLRequestDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/27/26.
//

import Foundation

public struct FetchUploadURLRequestDTO: Encodable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case catId
        case mediaType
    }

    public let catId: String?
    public let mediaType: String

    public init(
        catId: String?,
        mediaType: String
    ) {
        self.catId = catId
        self.mediaType = mediaType
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(catId, forKey: .catId)
        try container.encode(mediaType, forKey: .mediaType)
    }
}
