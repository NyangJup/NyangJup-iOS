//
//  ProfileClient.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

import CoreNetworkInterface

public struct ProfileClient: Sendable {
    public typealias UUID = String
    
    public let networkClient: NetworkClient?
    
    public var fetchIndividualCode: @Sendable (UUID) async throws -> String
    public var fetchProfile: @Sendable (UUID) async throws -> Profile
    public var updateNickname: @Sendable (UpdateNicknameRequestDTO) async throws -> Void
    
    public init(
        networkClient: NetworkClient?,
        fetchIndividualCode: @escaping @Sendable (UUID) -> String,
        fetchProfile: @escaping @Sendable (UUID) async throws -> Profile,
        updateNickname: @escaping @Sendable (UpdateNicknameRequestDTO) async throws -> Void
    ) {
        self.networkClient = networkClient
        self.fetchIndividualCode = fetchIndividualCode
        self.fetchProfile = fetchProfile
        self.updateNickname = updateNickname
    }
}
