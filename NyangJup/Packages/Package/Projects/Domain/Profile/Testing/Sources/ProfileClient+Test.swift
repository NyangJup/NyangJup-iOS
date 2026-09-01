//
//  ProfileClient+Test.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

import DomainProfileInterface

extension ProfileClient {
    public static let test = Self(
        networkClient: nil,
        fetchProfile: {
            Profile(
                individualCode: "A1B2C3",
                nickname: "집사"
            )
        },
        updateNickname: { _ in }
    )
}
