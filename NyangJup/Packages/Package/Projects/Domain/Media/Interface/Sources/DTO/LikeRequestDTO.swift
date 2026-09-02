//
//  LikeRequestDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

public struct LikeRequestDTO: Encodable, Sendable {
    public let isLiked: Bool

    public init(isLiked: Bool) {
        self.isLiked = isLiked
    }
}
