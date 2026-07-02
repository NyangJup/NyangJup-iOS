//
//  UploadURLResponseDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct UploadURLResponseDTO: Decodable {
    let uploadURL: String
    let fileName: String

    public init(
        uploadURL: String,
        fileName: String
    ) {
        self.uploadURL = uploadURL
        self.fileName = fileName
    }
}
