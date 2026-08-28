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
        
        try validate(data: data, response: response)
        
        if data.isEmpty {
            guard let emptyResponse = EmptyResponse() as? T else {
                throw NetworkError.decoding
            }
            
            return emptyResponse
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding
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
                request.httpBody = try encoder.encode(body)
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            } catch {
                throw NetworkError.encoding
            }
        }

        return request
    }

    func makeURL(_ endpoint: any Endpoint) throws -> URL {
        let path = endpoint.path.hasPrefix("/") ? String(endpoint.path.dropFirst()) : endpoint.path
        let pathURL = path.isEmpty ? endpoint.baseURL : endpoint.baseURL.appendingPathComponent(path)

        guard var components = URLComponents(url: pathURL, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }

        components.queryItems = endpoint.query

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        return url
    }

    func validate(
        data: Data,
        response: URLResponse
    ) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        let requestID = httpResponse.value(
            forHTTPHeaderField: "X-Request-Id"
        )
        
        let errorResponse = try? decoder.decode(
            APIErrorResponse.self,
            from: data
        )

        switch httpResponse.statusCode {
        case HTTPStatusCode.success:
            return
            
        case HTTPStatusCode.badRequest:
            throw NetworkError.badRequest(errorResponse)
        case HTTPStatusCode.requestTimeout:
            throw NetworkError.timeout
        case HTTPStatusCode.unauthorized:
            throw NetworkError.authorization(errorResponse)
        case HTTPStatusCode.notFound:
            throw NetworkError.notFound(errorResponse)
        case HTTPStatusCode.serverError:
            throw NetworkError.server(errorResponse)
        case HTTPStatusCode.clientError:
            throw NetworkError.client(errorResponse)
        default:
            throw NetworkError.unknown
        }
    }
}
