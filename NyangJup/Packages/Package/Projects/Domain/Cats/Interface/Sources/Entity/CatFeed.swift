//
//  CatFeed.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

import DomainMediaInterface

public struct CatFeed: Sendable {
    public let cat: Cat
    public let items: [Media]
    public let nextCursor: String?
    
    public init(
        cat: Cat,
        items: [Media],
        nextCursor: String?
    ) {
        self.cat = cat
        self.items = items
        self.nextCursor = nextCursor
    }
}
