import Foundation

import CoreNetworkInterface
import CoreSecureStorageInterface

public struct DeviceSecurityClient: Sendable {
    public var authenticate: @Sendable () async throws -> Void

    public init(authenticate: @escaping @Sendable () async throws -> Void) {
        self.authenticate = authenticate
    }
}

public enum AppAttestPurpose: String, Encodable, Sendable {
    case attestation = "ATTESTATION"
}

public struct AppAttestChallengeRequest: Encodable, Sendable {
    public let purpose: AppAttestPurpose

    public init(purpose: AppAttestPurpose) {
        self.purpose = purpose
    }
}

public struct AppAttestChallengeResponse: Decodable, Sendable {
    public let challengeId: String
    public let challenge: String
    public let expiresAt: String
}

public struct NewAppAttestationRequest: Encodable, Sendable {
    public let challengeId: String
    public let keyId: String
    public let attestationObject: String

    public init(
        challengeId: String,
        keyId: String,
        attestationObject: String
    ) {
        self.challengeId = challengeId
        self.keyId = keyId
        self.attestationObject = attestationObject
    }
}

public struct CompletedAppAttestationRequest: Encodable, Sendable {
    public let challengeId: String
    public let keyId: String
    public let assertion: String

    public init(challengeId: String, keyId: String, assertion: String) {
        self.challengeId = challengeId
        self.keyId = keyId
        self.assertion = assertion
    }
}

public struct AttestationRegistrationResponse: Decodable, Sendable {
    public let accessToken: String
}

public struct AppAttestationProvider: Sendable {
    public var isSupported: @Sendable () -> Bool
    public var generateKey: @Sendable () async throws -> String
    public var attestKey: @Sendable (_ keyId: String, _ clientDataHash: Data) async throws -> Data
    public var generateAssertion: @Sendable (_ keyId: String, _ clientDataHash: Data) async throws -> Data

    public init(
        isSupported: @escaping @Sendable () -> Bool,
        generateKey: @escaping @Sendable () async throws -> String,
        attestKey: @escaping @Sendable (_: String, _: Data) async throws -> Data,
        generateAssertion: @escaping @Sendable (_: String, _: Data) async throws -> Data
    ) {
        self.isSupported = isSupported
        self.generateKey = generateKey
        self.attestKey = attestKey
        self.generateAssertion = generateAssertion
    }
}

public enum DeviceSecurityError: Error, Equatable, Sendable {
    case appAttestUnsupported
    case invalidAppAttestKey
    case invalidChallenge
}
