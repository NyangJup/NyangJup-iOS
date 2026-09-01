//
//  ProfileClient.swift
//  NJPackage
//
//  Created by 정지훈 on 8/28/26.
//

import Foundation

import CoreNetworkInterface
import DomainProfileInterface

public extension ProfileClient {
    static func live(
        networkClient: NetworkClient
    ) -> Self {
        Self(
            networkClient: networkClient,
            fetchProfile: {
                let response: ProfileResponseDTO = try await networkClient.request(ProfileEndpoint.fetchProfile)
                return response.toEntity()
                
            },
            updateNickname: { request in
                let _: EmptyResponse = try await networkClient.request(
                    ProfileEndpoint.updateNickname(request)
                )
            }
        )
    }
}
