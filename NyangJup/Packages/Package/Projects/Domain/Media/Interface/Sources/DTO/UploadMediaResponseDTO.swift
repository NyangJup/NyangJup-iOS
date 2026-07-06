//
//  UploadMediaResponseDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct UploadMediaResponseDTO: Decodable {
    let catId: String
    let mediaId: String
    let mediaType: String
    let place: String

    public init(
        catId: String,
        mediaId: String,
        mediaType: String,
        place: String
    ) {
        self.catId = catId
        self.mediaId = mediaId
        self.mediaType = mediaType
        self.place = place
    }
}
