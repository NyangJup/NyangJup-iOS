//
//  UploadURL.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

public struct UploadURL: Equatable, Sendable {
    public let uploadURL: String
    public let fileName: String
    public let thumbnailUploadURL: String?
    public let thumbnailFileName: String?

    public init(
        uploadURL: String,
        fileName: String,
        thumbnailUploadURL: String? = nil,
        thumbnailFileName: String? = nil
    ) {
        self.uploadURL = uploadURL
        self.fileName = fileName
        self.thumbnailUploadURL = thumbnailUploadURL
        self.thumbnailFileName = thumbnailFileName
    }
}
