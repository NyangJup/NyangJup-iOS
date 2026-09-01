//
//  File.swift
//  NJPackage
//
//  Created by 정지훈 on 8/28/26.
//

import Foundation

import CoreNetworkInterface
import DomainProfileInterface

enum ProfileEndpoint: Endpoint {
    case fetchProfile
    case updateNickname(UpdateNicknameRequestDTO)
    
    var path: String {
        switch self {
        case .fetchProfile:
            "/profiles/me"
        case .updateNickname:
            "/profiles/me/nickname"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .fetchProfile:
                .get
        case .updateNickname:
                .patch
        }
    }
    
    var headers: [String: String]? { nil }
    var query: [URLQueryItem]? { nil }
    
    var body: Encodable? {
        switch self {
        case .fetchProfile:
            nil
        case let .updateNickname(request):
            request
        }
    }
    
    var requiresAuthorization: Bool {
        switch self {
        case .fetchProfile, .updateNickname:
            true
        }
    }
}
