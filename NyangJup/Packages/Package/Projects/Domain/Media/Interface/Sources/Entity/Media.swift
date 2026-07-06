//
//  Media.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct Media {
    public let id: String
    public let thumbnailURL: String
    public let mediaType: MediaType
    
    public init(
        id: String,
        thumbnailURL: String,
        mediaType: MediaType
    ) {
        self.id = id
        self.thumbnailURL = thumbnailURL
        self.mediaType = mediaType
    }
}
