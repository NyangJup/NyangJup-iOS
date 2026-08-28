//
//  File.swift
//  NJPackage
//
//  Created by 정지훈 on 7/1/26.
//

import Foundation

public enum NetworkError: Error, Equatable {
    case invalidURL
    case invalidResponse
    
    case authorization(APIErrorResponse?)
    case badRequest(APIErrorResponse?)
    case notFound(APIErrorResponse?)
    case timeout
    case networkUnavailable
    
    case server(APIErrorResponse?)
    case client(APIErrorResponse?)
    
    case decoding
    case encoding
    case unknown
}

public extension NetworkError {
    var errorMessage: String {
        switch self {
        case .invalidURL: "유효하지 않은 URL입니다."
        case .invalidResponse: "유효하지 않은 응답입니다."
        case let .authorization(response): response?.message ?? "인증에 실패했습니다."
        case let .badRequest(response): response?.message ?? "요청이 올바르지 않습니다."
        case let .notFound(response): response?.message ?? "요청한 리소스를 찾을 수 없습니다."
        case let .server(response): response?.message ?? "서버 에러입니다."
        case .decoding: "디코딩 에러입니다."
        case .encoding: "인코딩 에러입니다."
        case .unknown: "알 수 없는 오류가 발생했습니다."
        case .timeout: "타임 아웃이 발생했습니다."
        case .networkUnavailable: "네트워크 연결이 되어있지 않습니다."
        case let .client(response): response?.message ?? "클라이언트 에러입니다."
        }
    }
}
