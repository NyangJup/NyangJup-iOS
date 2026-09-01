//
//  DeviceSecurityClient+Live.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

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
                let challengeData = try AppAttestChallengeDecoder.decode(challenge.challenge)
                let clientDataHash = Data(SHA256.hash(data: challengeData))

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
            generateAssertion: { purpose, endpoint in
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
                let challengeData = try AppAttestChallengeDecoder.decode(challenge.challenge)
                let clientDataHash = try AppAttestCanonicalizer.clientDataHash(
                    challenge: challengeData,
                    endpoint: endpoint
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
