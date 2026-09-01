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

private final class InMemorySecureStorage: @unchecked Sendable {
    private var values: [String: String]

    init(values: [String: String] = [:]) {
        self.values = values
    }

    var client: SecureStorageClient {
        SecureStorageClient(
            save: { [weak self] value, key in self?.values[key] = value },
            read: { [weak self] key in self?.values[key] },
            delete: { [weak self] key in self?.values.removeValue(forKey: key) }
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
