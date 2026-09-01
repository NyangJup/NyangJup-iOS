//
//  ProfileClient.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

import CoreNetworkInterface

public struct ProfileClient: Sendable {
    public let networkClient: NetworkClient?
    
    public var fetchProfile: @Sendable () async throws -> Profile
    public var updateNickname: @Sendable (UpdateNicknameRequestDTO) async throws -> Void
    
    public init(
        networkClient: NetworkClient?,
        fetchProfile: @escaping @Sendable () async throws -> Profile,
        updateNickname: @escaping @Sendable (UpdateNicknameRequestDTO) async throws -> Void
    ) {
        self.networkClient = networkClient
        self.fetchProfile = fetchProfile
        self.updateNickname = updateNickname
    }
}
