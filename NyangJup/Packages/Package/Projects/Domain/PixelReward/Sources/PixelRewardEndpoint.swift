//
//  PixelRewardEndpoint.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

import Foundation

import CoreNetworkInterface

enum PixelRewardEndpoint: Endpoint {
    case balance
    case createAdSession
    case claimAdReward(sessionId: String)

    var path: String {
        switch self {
        case .balance:
            "/pixel-rewards/balance"
        case .createAdSession:
            "/pixel-rewards/ad-sessions"
        case let .claimAdReward(sessionId):
            "/pixel-rewards/ad-sessions/\(sessionId)/claim"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .balance:
            .get
        case .createAdSession, .claimAdReward:
            .post
        }
    }

    var headers: [String: String]? { nil }
    var query: [URLQueryItem]? { nil }
    var body: Encodable? { nil }
    var requiresAuthorization: Bool { true }
}
