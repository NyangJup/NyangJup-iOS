//
//  UpdateNicknameRequestDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct UpdateNicknameRequestDTO: Encodable, Sendable {
    public let nickname: String
    
    public init(
        nickname: String
    ) {
        self.nickname = nickname
    }
}
