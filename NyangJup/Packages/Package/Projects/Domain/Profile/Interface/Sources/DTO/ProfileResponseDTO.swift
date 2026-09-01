//
//  ProfileResponseDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 8/28/26.
//

import Foundation

public struct ProfileResponseDTO: Decodable, Sendable {
    public let individualCode: String
    public let nickname: String
    
    public func toEntity() -> Profile {
        Profile(
            individualCode: individualCode,
            nickname: nickname
        )
    }
}
