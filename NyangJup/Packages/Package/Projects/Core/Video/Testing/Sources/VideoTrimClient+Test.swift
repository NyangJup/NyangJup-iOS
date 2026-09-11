//
//  VideoTrimClient+Test.swift
//  NJPackage
//
//  Created by 정지훈 on 9/11/26.
//

import Foundation

import CoreVideoInterface

public extension VideoTrimClient {
    static let test = Self(
        loadDuration: { _ in 1 },
        generateThumbnails: { _, _, _ in [] },
        exportTrimmedVideo: { sourceURL, _, _ in sourceURL },
        generateUploadThumbnail: { _, _ in Data() }
    )
}
