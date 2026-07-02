//
//  Media.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct Media {
    let id: Int64
    let thumbnailURL: String
    let mediaType: MediaType
    
    public init(
        id: Int64,
        thumbnailURL: String,
        mediaType: MediaType
    ) {
        self.id = id
        self.thumbnailURL = thumbnailURL
        self.mediaType = mediaType
    }
}
