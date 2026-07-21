//
//  ImageDecodingError.swift
//  NJPackage
//
//  Created by 정지훈 on 7/21/26.
//

import Foundation

public enum ImageDecodingError: Error {
    case invalidTargetSize
    case sourceCreationFailed
    case thumbnailCreationFailed
}
