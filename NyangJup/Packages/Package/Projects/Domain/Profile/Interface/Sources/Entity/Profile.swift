//
//  Profile.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

public struct Profile: Sendable, Equatable {
    public let individualCode: String
    public let nickname: String
    
    public init(
        individualCode: String,
        nickname: String
    ) {
        self.individualCode = individualCode
        self.nickname = nickname
    }
}
