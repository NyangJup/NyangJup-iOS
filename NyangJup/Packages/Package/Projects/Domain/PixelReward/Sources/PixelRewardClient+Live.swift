import Foundation

import CoreNetworkInterface
import DomainDeviceSecurityInterface
import DomainPixelRewardInterface

public extension PixelRewardClient {
    static func live(
        networkClient: NetworkClient,
        deviceSecurityClient: DeviceSecurityClient
    ) -> Self {
        Self(
            fetchBalance: {
                do {
                    let response: PixelRewardBalanceResponseDTO = try await networkClient.request(
                        PixelRewardEndpoint.balance
                    )
                    return PixelRewardBalance(balance: response.balance)
                } catch {
                    throw mapPixelRewardError(error)
                }
            },
            createAdSession: {
                do {
                    let assertion = try await deviceSecurityClient.generateAssertion(
                        .adSession,
                        .post,
                        "/api/v1/pixel-rewards/ad-sessions",
                        Data()
                    )
                    let response: PixelRewardAdSessionResponseDTO = try await networkClient.request(
                        PixelRewardEndpoint.createAdSession(assertion)
                    )
                    return PixelRewardAdSession(
                        sessionId: response.sessionId,
                        expiresAt: try parseISO8601Date(response.expiresAt)
                    )
                } catch {
                    throw mapPixelRewardError(error)
                }
            },
            claimAdReward: { sessionId in
                do {
                    let canonicalPath = "/api/v1/pixel-rewards/ad-sessions/\(sessionId)/claim"
                    let assertion = try await deviceSecurityClient.generateAssertion(
                        .adReward,
                        .post,
                        canonicalPath,
                        Data()
                    )
                    let response: PixelRewardBalanceResponseDTO = try await networkClient.request(
                        PixelRewardEndpoint.claimAdReward(
                            sessionId: sessionId,
                            assertion: assertion
                        )
                    )
                    return PixelRewardBalance(balance: response.balance)
                } catch {
                    throw mapPixelRewardError(error)
                }
            }
        )
    }
}

private func parseISO8601Date(_ value: String) throws -> Date {
    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: value) {
        return date
    }

    formatter.formatOptions.insert(.withFractionalSeconds)
    guard let date = formatter.date(from: value) else {
        throw NetworkError.decoding
    }
    return date
}

private func mapPixelRewardError(_ error: any Error) -> any Error {
    guard let networkError = error as? NetworkError else {
        return error
    }

    let response: APIErrorResponse?
    switch networkError {
    case let .authorization(value),
         let .badRequest(value),
         let .notFound(value),
         let .server(value),
         let .client(value):
        response = value
    default:
        response = nil
    }

    switch response?.code {
    case "AD_SESSION_CONFLICT":
        return PixelRewardError.sessionUnavailable
    case "AD_SESSION_NOT_FOUND":
        return PixelRewardError.sessionNotFound
    case "APP_ATTEST_REPLAY":
        return PixelRewardError.appAttestReplay
    case "INVALID_APP_ATTEST_CHALLENGE":
        return PixelRewardError.invalidChallenge
    default:
        return networkError
    }
}
