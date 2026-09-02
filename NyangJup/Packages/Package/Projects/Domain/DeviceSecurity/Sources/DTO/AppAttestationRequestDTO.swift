//
//  AppAttestationRequestDTO.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

struct NewAppAttestationRequest: Encodable, Sendable {
    let challengeId: String
    let keyId: String
    let attestationObject: String
}

struct CompletedAppAttestationRequest: Encodable, Sendable {
    let challengeId: String
    let keyId: String
    let assertion: String
}
