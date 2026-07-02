//
//  ProfileClient.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

import CoreNetworkInterface

public struct ProfileClient: Sendable {
    public typealias ID = Int64
    
    public let networkClient: NetworkClient?
    
    public var fetchIndividualCode: @Sendable () -> String
    public var fetchProfile: @Sendable (ID) async throws -> Profile
    public var updateNickname: @Sendable (UpdateNicknameRequestDTO) async throws -> Void
    
    public init(
        networkClient: NetworkClient?,
        fetchIndividualCode: @escaping @Sendable () -> String,
        fetchProfile: @escaping @Sendable (ID) async throws -> Profile,
        updateNickname: @escaping @Sendable (UpdateNicknameRequestDTO) async throws -> Void
    ) {
        self.networkClient = networkClient
        self.fetchIndividualCode = fetchIndividualCode
        self.fetchProfile = fetchProfile
        self.updateNickname = updateNickname
    }
}
