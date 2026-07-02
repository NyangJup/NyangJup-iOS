//
//  CatsClient+Live.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

import CoreNetworkInterface
import DomainCatsInterface

extension CatsClient {
    static let live = Self(
        // FIXME: - 임시
        networkClient: nil,
        fetchCats: { id in
            return []
        }, fetchCatFeed: { id in
            // FIXME: - 임시
            CatFeed(
                id: 1,
                name: "꾸꾸",
                place: "구로구",
                thumbnailURL: "https://picsum.photos/200/300",
                feed: []
            )
        }
    )
}
