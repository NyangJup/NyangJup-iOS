//
//  CatResponseDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

import Foundation

public struct CatResponseDTO: Decodable, Sendable {
    public let id: String
    public let name: String
    public let place: String?
    public let imageURL: String

    public func toEntity() -> Cat {
        Cat(
            id: id,
            name: name,
            place: place,
            imageURL: imageURL
        )
    }
}
