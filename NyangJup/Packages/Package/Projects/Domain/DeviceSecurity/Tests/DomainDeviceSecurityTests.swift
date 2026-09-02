import Foundation
import Testing

import CoreNetworkInterface
import CoreSecureStorageInterface
@testable import DomainDeviceSecurity
import DomainDeviceSecurityInterface

@Test
func firstRegistrationSavesKeyAndAccessToken() async throws {
    let storage = InMemorySecureStorage()
    let network = RecordingNetworkClient()
    let client = DeviceSecurityClient.live(
        networkClient: NetworkClient(provider: network),
        secureStorageClient: storage.client,
        appAttestationProvider: .stub(keyId: "new-key")
    )

    try await client.authenticate()

    #expect(try storage.client.read(.appAttestKeyId) == "new-key")
    #expect(try storage.client.read(.accessToken) == "access-token")
    #expect(network.paths == [
        "/security/app-attest/challenges",
        "/security/app-attest/attestations"
    ])
}

@Test
func existingKeyUsesAssertionToRefreshAccessToken() async throws {
    let storage = InMemorySecureStorage(values: [.appAttestKeyId: "existing-key"])
    let network = RecordingNetworkClient()
    let client = DeviceSecurityClient.live(
        networkClient: NetworkClient(provider: network),
        secureStorageClient: storage.client,
        appAttestationProvider: .stub(keyId: "unused")
    )

    try await client.authenticate()

    #expect(try storage.client.read(.appAttestKeyId) == "existing-key")
    #expect(try storage.client.read(.accessToken) == "access-token")
    #expect(network.paths == [
        "/security/app-attest/challenges",
        "/security/app-attest/attestations"
    ])
}

@Test
func invalidExistingKeyIsReplacedAndRegistered() async throws {
    let storage = InMemorySecureStorage(values: [.appAttestKeyId: "invalid-key"])
    let network = RecordingNetworkClient()
    let attestationProvider = InvalidKeyAppAttestationProvider()
    let client = DeviceSecurityClient.live(
        networkClient: NetworkClient(provider: network),
        secureStorageClient: storage.client,
        appAttestationProvider: attestationProvider.client
    )

    try await client.authenticate()

    #expect(storage.deletedKeys == [.appAttestKeyId])
    #expect(try storage.client.read(.appAttestKeyId) == "replacement-key")
    #expect(try storage.client.read(.accessToken) == "access-token")
    #expect(attestationProvider.assertionAttempts == 1)
    #expect(attestationProvider.keyGenerationAttempts == 1)
    #expect(network.paths == [
        "/security/app-attest/challenges",
        "/security/app-attest/attestations"
    ])
}

@Test
func canonicalClientDataHashMatchesServerContract() {
    let hash = AppAttestCanonicalizer.clientDataHash(
        challenge: Data([1, 2, 3]),
        method: .post,
        path: "/api/v1/cats/pixel",
        body: Data(#"{"fileName":"a.jpg"}"#.utf8)
    )

    #expect(hash.hexString == "e41d5df0114127114183d857ef8709204e1011537d8a99d49bcf6f8d2120a464")
}

@Test
func protectedRequestUsesAuthenticatedChallengeAndReturnsAssertion() async throws {
    let storage = InMemorySecureStorage(values: [.appAttestKeyId: "stored-key"])
    let network = ProtectedRequestNetworkClient()
    let provider = RecordingAssertionProvider()
    let client = DeviceSecurityClient.live(
        networkClient: NetworkClient(provider: network),
        secureStorageClient: storage.client,
        appAttestationProvider: provider.client
    )

    let sessionAssertion = try await client.generateAssertion(
        .adSession,
        AssertionEndpoint(path: "/pixel-rewards/ad-sessions")
    )
    let rewardAssertion = try await client.generateAssertion(
        .adReward,
        AssertionEndpoint(path: "/pixel-rewards/ad-sessions/session-id/claim")
    )

    #expect(network.purposes == [.adSession, .adReward])
    #expect(network.authorizationRequirements == [true, true])
    #expect(provider.keyIds == ["stored-key", "stored-key"])
    #expect(sessionAssertion == AppAttestAssertion(
        keyId: "stored-key",
        challengeId: "challenge-id",
        assertion: "Ag=="
    ))
    #expect(rewardAssertion.challengeId == "challenge-id")
    #expect(provider.hashes[0] == AppAttestCanonicalizer.clientDataHash(
        challenge: Data([251, 255]),
        method: .post,
        path: "/api/v1/pixel-rewards/ad-sessions",
        body: Data()
    ))
}

@Test
func protectedEndpointPreservesRequestAndAddsAssertionHeaders() {
    let endpoint = AssertionEndpoint(
        path: "/pixel-rewards/ad-sessions",
        headers: ["X-Existing": "value"]
    )
    let protectedEndpoint = AppAttestProtectedEndpoint(
        base: endpoint,
        assertion: AppAttestAssertion(
            keyId: "key-id",
            challengeId: "challenge-id",
            assertion: "assertion"
        )
    )

    #expect(protectedEndpoint.baseURL == endpoint.baseURL)
    #expect(protectedEndpoint.path == endpoint.path)
    #expect(protectedEndpoint.method == endpoint.method)
    #expect(protectedEndpoint.query == endpoint.query)
    #expect(protectedEndpoint.body == nil)
    #expect(protectedEndpoint.requiresAuthorization == endpoint.requiresAuthorization)
    #expect(protectedEndpoint.headers == [
        "X-Existing": "value",
        "X-App-Attest-Key-Id": "key-id",
        "X-App-Attest-Challenge-Id": "challenge-id",
        "X-App-Attest-Assertion": "assertion"
    ])
}

private struct AssertionEndpoint: Endpoint {
    let path: String
    var headers: [String: String]? = nil

    let baseURL = URL(string: "https://api.nyangjup.store/api/v1")!
    let method = HTTPMethod.post
    let query: [URLQueryItem]? = nil
    let body: Encodable? = nil
    let requiresAuthorization = true
}

private final class InMemorySecureStorage: @unchecked Sendable {
    private var values: [String: String]
    private(set) var deletedKeys: [String] = []

    init(values: [String: String] = [:]) {
        self.values = values
    }

    var client: SecureStorageClient {
        SecureStorageClient(
            save: { [weak self] value, key in self?.values[key] = value },
            read: { [weak self] key in self?.values[key] },
            delete: { [weak self] key in
                self?.values.removeValue(forKey: key)
                self?.deletedKeys.append(key)
            }
        )
    }
}

private final class InvalidKeyAppAttestationProvider: @unchecked Sendable {
    private(set) var assertionAttempts = 0
    private(set) var keyGenerationAttempts = 0

    var client: AppAttestationProvider {
        AppAttestationProvider(
            isSupported: { true },
            generateKey: { [weak self] in
                self?.keyGenerationAttempts += 1
                return "replacement-key"
            },
            attestKey: { _, _ in Data([1]) },
            generateAssertion: { [weak self] _, _ in
                self?.assertionAttempts += 1
                throw DeviceSecurityError.invalidAppAttestKey
            }
        )
    }
}

private final class RecordingNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    private(set) var paths: [String] = []

    func request<T: Decodable>(_ endpoint: any Endpoint) async throws -> T {
        paths.append(endpoint.path)
        let json: String
        if paths.count == 1 {
            json = """
            {"challengeId":"challenge-id","challenge":"AQI","expiresAt":"2026-08-31T00:00:00Z"}
            """
        } else {
            json = """
            {"profile":{"individualCode":"A1B2C3","nickname":"집사"},"individualCode":"A1B2C3","accessToken":"access-token"}
            """
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: Data(json.utf8))
    }
}

private final class ProtectedRequestNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    private(set) var purposes: [AppAttestPurpose] = []
    private(set) var authorizationRequirements: [Bool] = []

    func request<T: Decodable>(_ endpoint: any Endpoint) async throws -> T {
        authorizationRequirements.append(endpoint.requiresAuthorization)
        if let request = endpoint.body as? AppAttestChallengeRequest {
            purposes.append(request.purpose)
        }
        let json = """
        {"challengeId":"challenge-id","challenge":"-_8","expiresAt":"2026-09-01T00:00:00Z"}
        """
        return try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }
}

private final class RecordingAssertionProvider: @unchecked Sendable {
    private(set) var keyIds: [String] = []
    private(set) var hashes: [Data] = []

    var client: AppAttestationProvider {
        AppAttestationProvider(
            isSupported: { true },
            generateKey: { "unused" },
            attestKey: { _, _ in Data() },
            generateAssertion: { [weak self] keyId, hash in
                self?.keyIds.append(keyId)
                self?.hashes.append(hash)
                return Data([2])
            }
        )
    }
}

private extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

private extension AppAttestationProvider {
    static func stub(keyId: String) -> Self {
        Self(
            isSupported: { true },
            generateKey: { keyId },
            attestKey: { _, _ in Data([1]) },
            generateAssertion: { _, _ in Data([2]) }
        )
    }
}
