import Foundation

import CoreNetworkInterface
import DomainDeviceSecurityInterface

enum PixelRewardEndpoint: Endpoint {
    case balance
    case createAdSession(AppAttestAssertion)
    case claimAdReward(sessionId: String, assertion: AppAttestAssertion)

    var path: String {
        switch self {
        case .balance:
            "/pixel-rewards/balance"
        case .createAdSession:
            "/pixel-rewards/ad-sessions"
        case let .claimAdReward(sessionId, _):
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

    var headers: [String: String]? {
        switch self {
        case .balance:
            nil
        case let .createAdSession(assertion), let .claimAdReward(_, assertion):
            [
                "X-App-Attest-Key-Id": assertion.keyId,
                "X-App-Attest-Challenge-Id": assertion.challengeId,
                "X-App-Attest-Assertion": assertion.assertion
            ]
        }
    }

    var query: [URLQueryItem]? { nil }
    var body: Encodable? { nil }
    var requiresAuthorization: Bool { true }
}
