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
        fetchIndividualCode: {
            "NYANG-7K2P"
        },
        fetchProfile: { id in
            Profile(
                id: id,
                nickname: "집사"
            )
        },
        updateNickname: { _ in }
    )
}
