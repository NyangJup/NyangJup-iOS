//
//  NZImageLoaderError.swift
//  NJPackage
//
//  Created by 정지훈 on 7/21/26.
//

import Foundation

public enum NZImageLoaderError: Error, Sendable {
    case cacheMiss
    case invalidResponse
    case emptyData
}
