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
}

public extension Endpoint {
    var baseURL: URL {
        let fallbackURL = URL(string: "https://httpbin.org")!
        
        let apiBaseURL: String? = ProcessInfo.processInfo.environment["API_BASE_URL"] ??
        Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        
        guard let urlString = apiBaseURL,
              let url = URL(string: urlString) else {
            return fallbackURL
        }
        return url
    }
}
