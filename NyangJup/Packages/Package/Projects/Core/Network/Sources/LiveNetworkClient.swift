import Foundation
import CoreNetworkInterface

public struct LiveNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let interceptors: [any NetworkInterceptor]
    
    public init(
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        interceptors: [any NetworkInterceptor] = []
    ) {
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
        self.interceptors = interceptors
    }
    
    public func request<T: Decodable>(_ endpoint: any Endpoint) async throws -> T {
        let request = try await intercept(makeURLRequest(endpoint), endpoint: endpoint)
        let (data, response) = try await session.data(for: request)

        try validate(response)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
}

public extension NetworkClient {
    static let live = NetworkClient(provider: LiveNetworkClient())
}

private extension LiveNetworkClient {
    func intercept(_ request: URLRequest, endpoint: any Endpoint) async throws -> URLRequest {
        var request = request
        
        for interceptor in interceptors {
            request = try await interceptor.adapt(request, endpoint: endpoint)
        }
        
        return request
    }
    
    func makeURLRequest(_ endpoint: any Endpoint) throws -> URLRequest {
        let url = try makeURL(endpoint)
        var request = URLRequest(url: url)
        
        request.httpMethod = endpoint.method.rawValue
        
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = endpoint.body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            } catch {
                throw NetworkError.encodingError
            }
        }

        return request
    }

    func makeURL(_ endpoint: any Endpoint) throws -> URL {
        let path = endpoint.path.hasPrefix("/") ? String(endpoint.path.dropFirst()) : endpoint.path
        let pathURL = path.isEmpty ? endpoint.baseURL : endpoint.baseURL.appendingPathComponent(path)

        guard var components = URLComponents(url: pathURL, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURLError
        }

        components.queryItems = endpoint.query

        guard let url = components.url else {
            throw NetworkError.invalidURLError
        }

        return url
    }

    func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponseError
        }

        switch httpResponse.statusCode {
        case HTTPStatusCode.success:
            return
        case HTTPStatusCode.badRequest:
            throw NetworkError.badRequestError(code: nil)
        case HTTPStatusCode.unauthorized:
            throw NetworkError.authorizationError
        case HTTPStatusCode.notFound:
            throw NetworkError.notFoundError
        case HTTPStatusCode.serverError:
            throw NetworkError.serverError
        default:
            throw NetworkError.unknownError
        }
    }
}
