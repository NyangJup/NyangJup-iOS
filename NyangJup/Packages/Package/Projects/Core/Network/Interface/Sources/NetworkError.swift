//
//  File.swift
//  NJPackage
//
//  Created by 정지훈 on 7/1/26.
//

import Foundation

public enum NetworkError: Error, Equatable {
    case invalidURLError
    case invalidResponseError
    case authorizationError
    case badRequestError(code: String?)
    case notFoundError
    case serverError
    case decodingError
    case encodingError
    case unknownError
}

public extension NetworkError {
    var errorMessage: String {
        switch self {
        case .invalidURLError: "유효하지 않은 URL입니다."
        case .invalidResponseError: "유효하지 않은 응답입니다."
        case .authorizationError: "인증에 실패했습니다."
        case .badRequestError: "요청이 올바르지 않습니다."
        case .notFoundError: "요청한 리소스를 찾을 수 없습니다."
        case .serverError: "서버 에러입니다."
        case .decodingError: "디코딩 에러입니다."
        case .encodingError: "인코딩 에러입니다."
        case .unknownError: "알 수 없는 오류가 발생했습니다."
        }
    }
}
