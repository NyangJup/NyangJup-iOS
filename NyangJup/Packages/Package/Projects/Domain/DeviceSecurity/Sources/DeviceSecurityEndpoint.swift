//
//  DeviceSecurityEndpoint.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

import Foundation

import CoreNetworkInterface
import DomainDeviceSecurityInterface

enum DeviceSecurityEndpoint: Endpoint {
    case issueChallenge(AppAttestChallengeRequest)
    case registerNew(NewAppAttestationRequest)
    case registerCompleted(CompletedAppAttestationRequest)

    var path: String {
        switch self {
        case .issueChallenge:
            "/security/app-attest/challenges"
        case .registerNew, .registerCompleted:
            "/security/app-attest/attestations"
        }
    }

    var method: HTTPMethod { .post }
    var headers: [String: String]? { nil }
    var query: [URLQueryItem]? { nil }

    var body: Encodable? {
        switch self {
        case let .issueChallenge(request): request
        case let .registerNew(request): request
        case let .registerCompleted(request): request
        }
    }

    var requiresAuthorization: Bool {
        switch self {
        case let .issueChallenge(request):
            request.purpose != .attestation
        case .registerNew, .registerCompleted:
            false
        }
    }
}
