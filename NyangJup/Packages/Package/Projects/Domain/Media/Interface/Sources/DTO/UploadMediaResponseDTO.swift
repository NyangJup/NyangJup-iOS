//
//  UploadMediaResponseDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct UploadMediaResponseDTO: Decodable {
    let catId: Int64
    let mediaId: Int64
    let mediaType: String
    let place: String

    public init(
        catId: Int64,
        mediaId: Int64,
        mediaType: String,
        place: String
    ) {
        self.catId = catId
        self.mediaId = mediaId
        self.mediaType = mediaType
        self.place = place
    }
}
