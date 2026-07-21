//
//  FeedPage.swift
//  NJPackage
//
//  Created by 정지훈 on 7/16/26.
//

import Foundation

public struct FeedPage {
    public let items: [Media]
    public let nextCursor: String?

    public init(
        items: [Media],
        nextCursor: String?
    ) {
        self.items = items
        self.nextCursor = nextCursor
    }
}
