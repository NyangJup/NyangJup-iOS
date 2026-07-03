//
//  Media.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct Media {
    public let id: Int64
    public let thumbnailURL: String
    public let mediaType: MediaType
    
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
