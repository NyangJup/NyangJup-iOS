//
//  VideoUploadRequest.swift
//  NJPackage
//
//  Created by 정지훈 on 9/7/26.
//

import Foundation

public struct VideoUploadRequest: Sendable {
    public let sourceURL: URL
    public let trimStartTime: Double
    public let trimEndTime: Double
    public let catID: String?
    public let place: String?
    public let comment: String

    public init(
        sourceURL: URL,
        trimStartTime: Double,
        trimEndTime: Double,
        catID: String?,
        place: String?,
        comment: String
    ) {
        self.sourceURL = sourceURL
        self.trimStartTime = trimStartTime
        self.trimEndTime = trimEndTime
        self.catID = catID
        self.place = place
        self.comment = comment
    }
}
