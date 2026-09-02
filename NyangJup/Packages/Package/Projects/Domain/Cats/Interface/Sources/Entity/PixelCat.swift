//
//  PixelCat.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

import Foundation

public struct PixelCat: Sendable, Equatable {
    public let fileName: String
    public let imageURL: String

    public init(fileName: String, imageURL: String) {
        self.fileName = fileName
        self.imageURL = imageURL
    }
}
