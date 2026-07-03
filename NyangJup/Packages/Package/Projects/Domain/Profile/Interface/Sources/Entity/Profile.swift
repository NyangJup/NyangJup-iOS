//
//  Profile.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct Profile {
    public let id: Int64
    public let nickname: String
    
    public init(
        id: Int64,
        nickname: String
    ) {
        self.id = id
        self.nickname = nickname
    }
}
