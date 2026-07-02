//
//  File.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct Cat {
    let id: Int64
    let name: String
    let place: String
    let imageURL: String
    
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
