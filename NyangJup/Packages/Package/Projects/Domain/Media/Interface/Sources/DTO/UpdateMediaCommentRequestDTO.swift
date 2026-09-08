//
//  UpdateMediaCommentRequestDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 9/7/26.
//

import Foundation

public struct UpdateMediaCommentRequestDTO: Encodable, Sendable {
    public let comment: String

    public init(comment: String) {
        self.comment = comment
    }
}
