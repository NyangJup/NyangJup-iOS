//
//  CreateCatRequestDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import Foundation

public struct CreateCatRequestDTO: Encodable, Sendable {
    public let name: String
    public let appearanceKey: String

    public init(
        name: String,
        appearanceKey: String
    ) {
        self.name = name
        self.appearanceKey = appearanceKey
    }
}
