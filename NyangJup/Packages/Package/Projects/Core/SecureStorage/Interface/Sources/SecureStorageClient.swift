//
//  SecureStorageClient.swift
//  NJPackage
//
//  Created by 정지훈 on 8/28/26.
//

import Foundation

public struct SecureStorageClient: Sendable {
    public var save: @Sendable (_ value: String, _ key: String) throws -> Void
    public var read: @Sendable (_ key: String) throws -> String?
    public var delete: @Sendable (_ key: String) throws -> Void
    
    public init(
        save: @Sendable @escaping (_: String, _: String) throws -> Void,
        read: @Sendable @escaping (_: String) throws -> String?,
        delete: @Sendable @escaping (_: String) throws -> Void
    ) {
        self.save = save
        self.read = read
        self.delete = delete
    }
}

public extension String {
    static let accessToken = "accessToken"

    static let appAttestKeyId = "appAttestKeyId"
    static let appAttestRegistered = "appAttestRegistered"

}

