//
//  CatFeed.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

import DomainMediaInterface

public struct CatFeed {
    let id: Int64
    let name: String
    let place: String
    let thumbnailURL: String
    
    let feed: [Media]
    
    public init(
        id: Int64,
        name: String,
        place: String,
        thumbnailURL: String,
        feed: [Media]
    ) {
        self.id = id
        self.name = name
        self.place = place
        self.thumbnailURL = thumbnailURL
        self.feed = feed
    }
}
