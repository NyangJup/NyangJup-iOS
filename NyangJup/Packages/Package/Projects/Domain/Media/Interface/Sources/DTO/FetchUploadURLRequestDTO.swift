//
//  FetchUploadURLRequestDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/27/26.
//

import Foundation

public struct FetchUploadURLRequestDTO: Encodable, Sendable {
    public let catId: String?
    public let mediaType: String

    public init(
        catId: String?,
        mediaType: String
    ) {
        self.catId = catId
        self.mediaType = mediaType
    }
}
