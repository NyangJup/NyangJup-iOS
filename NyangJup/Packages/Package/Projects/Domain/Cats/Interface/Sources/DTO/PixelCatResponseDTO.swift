//
//  PixelCatResponseDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

import Foundation

public struct PixelCatResponseDTO: Decodable, Sendable {
    public let fileName: String
    public let imageURL: String

    public func toEntity() -> PixelCat {
        PixelCat(fileName: fileName, imageURL: imageURL)
    }
}
