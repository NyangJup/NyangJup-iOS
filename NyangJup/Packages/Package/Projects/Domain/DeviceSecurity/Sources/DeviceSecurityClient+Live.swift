import CryptoKit
import Foundation

import CoreNetworkInterface
import CoreSecureStorageInterface
import DomainDeviceSecurityInterface

public extension DeviceSecurityClient {
    static func live(
        networkClient: NetworkClient,
        secureStorageClient: SecureStorageClient,
        appAttestationProvider: AppAttestationProvider = .live
    ) -> Self {
        Self(
            authenticate: {
                guard appAttestationProvider.isSupported() else {
                    throw DeviceSecurityError.appAttestUnsupported
                }

                let challenge: AppAttestChallengeResponse = try await networkClient.request(
                    DeviceSecurityEndpoint.issueChallenge(
                        AppAttestChallengeRequest(purpose: .attestation)
                    )
                )
                let clientDataHash = Data(try SHA256.hash(data: challenge.challengeData))

                let response: AttestationRegistrationResponse
                if let keyId = try secureStorageClient.read(.appAttestKeyId) {
                    do {
                        let assertion = try await appAttestationProvider.generateAssertion(keyId, clientDataHash)
                        response = try await networkClient.request(
                            DeviceSecurityEndpoint.registerCompleted(
                                CompletedAppAttestationRequest(
                                    challengeId: challenge.challengeId,
                                    keyId: keyId,
                                    assertion: assertion.base64EncodedString()
                                )
                            )
                        )
                    } catch DeviceSecurityError.invalidAppAttestKey {
                        try secureStorageClient.delete(.appAttestKeyId)
                        let keyId = try await appAttestationProvider.generateKey()
                        let attestation = try await appAttestationProvider.attestKey(keyId, clientDataHash)
                        response = try await networkClient.request(
                            DeviceSecurityEndpoint.registerNew(
                                NewAppAttestationRequest(
                                    challengeId: challenge.challengeId,
                                    keyId: keyId,
                                    attestationObject: attestation.base64EncodedString()
                                )
                            )
                        )
                        try secureStorageClient.save(keyId, .appAttestKeyId)
                    }
                } else {
                    let keyId = try await appAttestationProvider.generateKey()
                    let attestation = try await appAttestationProvider.attestKey(keyId, clientDataHash)
                    response = try await networkClient.request(
                        DeviceSecurityEndpoint.registerNew(
                            NewAppAttestationRequest(
                                challengeId: challenge.challengeId,
                                keyId: keyId,
                                attestationObject: attestation.base64EncodedString()
                            )
                        )
                    )
                    try secureStorageClient.save(keyId, .appAttestKeyId)
                }

                try secureStorageClient.save(response.accessToken, .accessToken)
            },
            generateAssertion: { purpose, method, path, body in
                guard appAttestationProvider.isSupported() else {
                    throw DeviceSecurityError.appAttestUnsupported
                }
                guard let keyId = try secureStorageClient.read(.appAttestKeyId) else {
                    throw DeviceSecurityError.invalidAppAttestKey
                }

                let challenge: AppAttestChallengeResponse = try await networkClient.request(
                    DeviceSecurityEndpoint.issueChallenge(
                        AppAttestChallengeRequest(purpose: purpose)
                    )
                )
                let clientDataHash = AppAttestCanonicalizer.clientDataHash(
                    challenge: try challenge.challengeData,
                    method: method,
                    path: path,
                    body: body
                )
                let assertion = try await appAttestationProvider.generateAssertion(keyId, clientDataHash)

                return AppAttestAssertion(
                    keyId: keyId,
                    challengeId: challenge.challengeId,
                    assertion: assertion.base64EncodedString()
                )
            }
        )
    }
}

enum AppAttestCanonicalizer {
    static func clientDataHash(
        challenge: Data,
        method: HTTPMethod,
        path: String,
        body: Data
    ) -> Data {
        var canonical = Data()
        canonical.append(challenge)
        canonical.append(0)
        canonical.append(Data(method.rawValue.uppercased().utf8))
        canonical.append(0)
        canonical.append(Data(path.utf8))
        canonical.append(0)
        canonical.append(Data(SHA256.hash(data: body)))
        return Data(SHA256.hash(data: canonical))
    }
}

private extension AppAttestChallengeResponse {
    var challengeData: Data {
        get throws {
            let base64 = challenge
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            let padded = base64 + String(repeating: "=", count: (4 - base64.count % 4) % 4)

            guard let data = Data(base64Encoded: padded) else {
                throw DeviceSecurityError.invalidChallenge
            }
            return data
        }
    }
}
