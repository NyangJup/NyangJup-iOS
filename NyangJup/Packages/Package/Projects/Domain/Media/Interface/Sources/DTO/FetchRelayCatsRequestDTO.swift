//
//  FetchRelayCatsRequestDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/22/26.
//

import Foundation

public struct FetchRelayCatsRequestDTO: Sendable {
    public let anchorId: String
    public let catId: String
    public let beforeCount: Int
    public let afterCount: Int

    public init(
        anchorId: String,
        catId: String,
        beforeCount: Int,
        afterCount: Int
    ) {
        self.anchorId = anchorId
        self.catId = catId
        self.beforeCount = beforeCount
        self.afterCount = afterCount
    }
}
