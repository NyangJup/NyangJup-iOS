//
//  UploadMediaRequestDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct UploadMediaRequestDTO: Encodable, Sendable {
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
}
