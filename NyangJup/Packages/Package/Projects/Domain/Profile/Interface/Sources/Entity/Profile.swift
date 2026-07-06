//
//  Profile.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct Profile {
    public let id: String
    public let nickname: String
    
    public init(
        id: String,
        nickname: String
    ) {
        self.id = id
        self.nickname = nickname
    }
}
