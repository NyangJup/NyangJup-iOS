//
//  UploadMediaRequestDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct UploadMediaRequestDTO: Encodable {
    let catId: String
    let mediaType: String
    let place: String

    public init(
        catId: String,
        mediaType: String,
        place: String
    ) {
        self.catId = catId
        self.mediaType = mediaType
        self.place = place
    }
}
