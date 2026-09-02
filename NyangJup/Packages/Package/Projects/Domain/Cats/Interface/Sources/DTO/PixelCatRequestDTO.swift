//
//  PixelCatRequestDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

import Foundation

public struct PixelCatRequestDTO: Encodable, Sendable {
    public let fileName: String

    public init(fileName: String) {
        self.fileName = fileName
    }
}
