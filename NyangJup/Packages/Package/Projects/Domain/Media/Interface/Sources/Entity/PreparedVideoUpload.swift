//
//  PreparedVideoUpload.swift
//  NJPackage
//
//  Created by 정지훈 on 9/8/26.
//

import Foundation

public struct PreparedVideoUpload: Sendable {
    public let videoURL: URL
    public let thumbnailData: Data
    public let catID: String?
    public let place: String?
    public let comment: String

    public init(
        videoURL: URL,
        thumbnailData: Data,
        catID: String?,
        place: String?,
        comment: String
    ) {
        self.videoURL = videoURL
        self.thumbnailData = thumbnailData
        self.catID = catID
        self.place = place
        self.comment = comment
    }
}
