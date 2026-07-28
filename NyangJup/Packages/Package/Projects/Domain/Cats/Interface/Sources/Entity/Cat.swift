//
//  Cat.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct Cat: Sendable {
    public let id: String
    public let name: String
    public let place: String?
    public let appearanceKey: String
    
    public init(
        id: String,
        name: String,
        place: String?,
        appearanceKey: String
    ) {
        self.id = id
        self.name = name
        self.place = place
        self.appearanceKey = appearanceKey
    }
}
