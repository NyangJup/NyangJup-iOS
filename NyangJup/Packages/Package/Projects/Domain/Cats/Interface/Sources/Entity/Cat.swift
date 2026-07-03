//
//  File.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct Cat {
    public let id: Int64
    public let name: String
    public let place: String
    public let imageURL: String
    
    public init(
        id: Int64,
        name: String,
        place: String,
        imageURL: String
    ) {
        self.id = id
        self.name = name
        self.place = place
        self.imageURL = imageURL
    }
}
