//
//  RelayPage.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

public struct RelayPage: Sendable {
    public let items: [RelayCat]
    public let anchorIndex: Int
    public let previousCursor: String?
    public let nextCursor: String?

    public init(
        items: [RelayCat],
        anchorIndex: Int,
        previousCursor: String?,
        nextCursor: String?
    ) {
        self.items = items
        self.anchorIndex = anchorIndex
        self.previousCursor = previousCursor
        self.nextCursor = nextCursor
    }
}
