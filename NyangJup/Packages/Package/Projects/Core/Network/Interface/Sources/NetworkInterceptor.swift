//
//  NetworkInterceptor.swift
//  NJPackage
//
//  Created by 정지훈 on 7/1/26.
//

import Foundation

public protocol NetworkInterceptor: Sendable {
    func adapt(_ request: URLRequest, endpoint: any Endpoint) async throws -> URLRequest
}
