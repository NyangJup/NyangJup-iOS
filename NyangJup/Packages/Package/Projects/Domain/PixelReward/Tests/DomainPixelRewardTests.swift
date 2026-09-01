import Foundation
import Testing

import CoreNetworkInterface
import DomainDeviceSecurityInterface
@testable import DomainPixelReward
import DomainPixelRewardInterface

@Test
func pixelRewardClientMapsResponsesAndBuildsProtectedRequests() async throws {
    let network = RecordingPixelRewardNetworkClient(responses: [
        .success(Data(#"{"balance":1}"#.utf8)),
        .success(Data(#"{"sessionId":"session-id","expiresAt":"2026-09-01T01:02:03.456Z"}"#.utf8)),
        .success(Data(#"{"balance":2}"#.utf8))
    ])
    let security = RecordingDeviceSecurityClient()
    let client = PixelRewardClient.live(
        networkClient: NetworkClient(provider: network),
        deviceSecurityClient: security.client
    )

    let initialBalance = try await client.fetchBalance()
    let session = try await client.createAdSession()
    let claimedBalance = try await client.claimAdReward("session-id")
    let expectedExpiration = try #require(
        ISO8601DateFormatter.fractional.date(from: "2026-09-01T01:02:03.456Z")
    )

    #expect(initialBalance == PixelRewardBalance(balance: 1))
    #expect(session.sessionId == "session-id")
    #expect(session.expiresAt == expectedExpiration)
    #expect(claimedBalance == PixelRewardBalance(balance: 2))
    #expect(network.paths == [
        "/pixel-rewards/balance",
        "/pixel-rewards/ad-sessions",
        "/pixel-rewards/ad-sessions/session-id/claim"
    ])
    #expect(network.methods == ["GET", "POST", "POST"])
    #expect(network.authorizationRequirements == [true, true, true])
    #expect(network.headers[0] == nil)
    #expect(network.headers[1] == RecordingDeviceSecurityClient.assertionHeaders)
    #expect(network.headers[2] == RecordingDeviceSecurityClient.assertionHeaders)
    #expect(security.purposes == [.adSession, .adReward])
    #expect(security.paths == [
        "/api/v1/pixel-rewards/ad-sessions",
        "/api/v1/pixel-rewards/ad-sessions/session-id/claim"
    ])
    #expect(security.methods == ["POST", "POST"])
    #expect(security.bodySizes == [0, 0])
}

@Test
func invalidSessionExpirationThrowsDecodingError() async throws {
    let client = makeClient(response: .success(
        Data(#"{"sessionId":"session-id","expiresAt":"not-a-date"}"#.utf8)
    ))

    await #expect(throws: NetworkError.decoding) {
        try await client.createAdSession()
    }
}

@Test
func sessionConflictMapsToSessionUnavailable() async throws {
    let client = makeClient(response: .failure(.client(
        APIErrorResponse(status: 409, message: "conflict", code: "AD_SESSION_CONFLICT")
    )))

    await #expect(throws: PixelRewardError.sessionUnavailable) {
        try await client.claimAdReward("session-id")
    }
}

@Test
func missingSessionMapsToSessionNotFound() async throws {
    let client = makeClient(response: .failure(.notFound(
        APIErrorResponse(status: 404, message: "not found", code: "AD_SESSION_NOT_FOUND")
    )))

    await #expect(throws: PixelRewardError.sessionNotFound) {
        try await client.claimAdReward("session-id")
    }
}

@Test
func assertionReplayMapsToAppAttestReplay() async throws {
    let client = makeClient(response: .failure(.client(
        APIErrorResponse(status: 409, message: "replay", code: "APP_ATTEST_REPLAY")
    )))

    await #expect(throws: PixelRewardError.appAttestReplay) {
        try await client.createAdSession()
    }
}

@Test
func expiredChallengeMapsToInvalidChallenge() async throws {
    let client = makeClient(response: .failure(.client(
        APIErrorResponse(status: 409, message: "invalid challenge", code: "INVALID_APP_ATTEST_CHALLENGE")
    )))

    await #expect(throws: PixelRewardError.invalidChallenge) {
        try await client.createAdSession()
    }
}

private func makeClient(response: Result<Data, NetworkError>) -> PixelRewardClient {
    PixelRewardClient.live(
        networkClient: NetworkClient(
            provider: RecordingPixelRewardNetworkClient(responses: [response])
        ),
        deviceSecurityClient: RecordingDeviceSecurityClient().client
    )
}

private final class RecordingPixelRewardNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    private var responses: [Result<Data, NetworkError>]
    private(set) var paths: [String] = []
    private(set) var methods: [String] = []
    private(set) var headers: [[String: String]?] = []
    private(set) var authorizationRequirements: [Bool] = []

    init(responses: [Result<Data, NetworkError>]) {
        self.responses = responses
    }

    func request<T: Decodable>(_ endpoint: any Endpoint) async throws -> T {
        paths.append(endpoint.path)
        methods.append(endpoint.method.rawValue)
        headers.append(endpoint.headers)
        authorizationRequirements.append(endpoint.requiresAuthorization)
        let data = try responses.removeFirst().get()
        return try JSONDecoder().decode(T.self, from: data)
    }
}

private final class RecordingDeviceSecurityClient: @unchecked Sendable {
    private(set) var purposes: [AppAttestPurpose] = []
    private(set) var methods: [String] = []
    private(set) var paths: [String] = []
    private(set) var bodySizes: [Int] = []

    var client: DeviceSecurityClient {
        DeviceSecurityClient(
            authenticate: {},
            generateAssertion: { [weak self] purpose, method, path, body in
                self?.purposes.append(purpose)
                self?.methods.append(method.rawValue)
                self?.paths.append(path)
                self?.bodySizes.append(body.count)
                return Self.assertion
            }
        )
    }

    static let assertion = AppAttestAssertion(
        keyId: "key-id",
        challengeId: "challenge-id",
        assertion: "assertion"
    )
    static let assertionHeaders = [
        "X-App-Attest-Key-Id": "key-id",
        "X-App-Attest-Challenge-Id": "challenge-id",
        "X-App-Attest-Assertion": "assertion"
    ]
}

private extension ISO8601DateFormatter {
    static var fractional: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        return formatter
    }
}
