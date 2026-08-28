//
//  Endpoint.swift
//  NJPackage
//
//  Created by 정지훈 on 7/1/26.
//

import Foundation

public protocol Endpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var query: [URLQueryItem]? { get }
    var body: Encodable? { get }
    var requiresAuthorization: Bool { get }
}

public extension Endpoint {
    var baseURL: URL {
        guard
            let value = Bundle.main.object(
                forInfoDictionaryKey: "API_BASE_URL"
            ) as? String,
            let url = URL(string: value),
            url.scheme == "https"
        else {
            preconditionFailure("API_BASE_URL 설정을 확인해 주세요.")
        }
        
        return url
    }
}
