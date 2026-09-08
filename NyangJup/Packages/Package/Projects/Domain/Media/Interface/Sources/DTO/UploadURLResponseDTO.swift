//
//  UploadURLResponseDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct UploadURLResponseDTO: Decodable, Sendable {
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

    public func toEntity() -> UploadURL {
        UploadURL(
            uploadURL: uploadURL,
            fileName: fileName,
            thumbnailUploadURL: thumbnailUploadURL,
            thumbnailFileName: thumbnailFileName
        )
    }
}
