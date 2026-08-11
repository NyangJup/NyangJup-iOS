//
//  CreateCatRequestDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import Foundation

public struct CreateCatRequestDTO: Encodable, Sendable {
    public let name: String
    public let place: String
    public let fileName: String

    public init(
        name: String,
        place: String = "",
        fileName: String
    ) {
        self.name = name
        self.place = place
        self.fileName = fileName
    }
}
