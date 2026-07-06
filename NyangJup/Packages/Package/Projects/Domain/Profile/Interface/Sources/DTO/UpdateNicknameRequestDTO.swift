//
//  UpdateNicknameRequestDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct UpdateNicknameRequestDTO: Encodable {
    let id: String
    let nickname: String
    
    public init(
        id: String,
        nickname: String
    ) {
        self.id = id
        self.nickname = nickname
    }
}
