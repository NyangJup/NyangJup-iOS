//
//  BearerTokenInterceptor.swift
//  NJPackage
//
//  Created by 정지훈 on 8/28/26.
//

import Foundation

import CoreNetworkInterface
import CoreSecureStorageInterface

public struct BearerTokenInterceptor: NetworkInterceptor {
    private let secureStorageClient: SecureStorageClient
    
    public init(secureStorageClient: SecureStorageClient) {
        self.secureStorageClient = secureStorageClient
    }
    
    public func adapt(
        _ request: URLRequest,
        endpoint: any Endpoint
    ) async throws -> URLRequest {
        guard endpoint.requiresAuthorization else { return request }
        
        guard let accessToken = try secureStorageClient.read(.accessToken) else {
            throw SecureStorageError.invalidStoredValue
        }
        
        var request = request
        
        request.setValue(
            "Bearer \(accessToken)",
            forHTTPHeaderField: "Authorization"
        )
        
        return request
    }
}
