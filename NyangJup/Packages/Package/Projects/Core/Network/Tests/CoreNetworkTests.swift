import Foundation
import Testing

@testable import CoreNetwork
import CoreNetworkInterface
import CoreSecureStorageInterface

@Test
func testExample() {}

@Test
func bearerTokenInterceptorAddsStoredTokenToAuthorizedRequest() async throws {
    let storage = SecureStorageClient(
        save: { _, _ in },
        read: { key in key == .accessToken ? "access-token" : nil },
        delete: { _ in }
    )
    let interceptor = BearerTokenInterceptor(secureStorageClient: storage)
    let request = try await interceptor.adapt(
        URLRequest(url: URL(string: "https://example.com")!),
        endpoint: AuthorizedEndpoint()
    )

    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer access-token")
}

private struct AuthorizedEndpoint: Endpoint {
    let baseURL = URL(string: "https://example.com")!
    let path = "/profiles/me"
    let method: HTTPMethod = .get
    let headers: [String: String]? = nil
    let query: [URLQueryItem]? = nil
    let body: Encodable? = nil
    let requiresAuthorization = true
}
