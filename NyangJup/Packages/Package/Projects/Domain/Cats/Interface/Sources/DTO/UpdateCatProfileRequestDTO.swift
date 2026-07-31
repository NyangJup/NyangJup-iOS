//
//  UpdateCatProfileRequestDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/31/26.
//

import Foundation

public struct UpdateCatProfileRequestDTO: Encodable, Sendable {
    public let name: String
    public let place: String

    public init(
        name: String,
        place: String
    ) {
        self.name = name
        self.place = place
    }
}
