//
//  CatsEndpoint.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

import Foundation

import CoreNetworkInterface
import DomainCatsInterface

enum CatsEndpoint: Endpoint {
    case fetchCats
    case createCat(CreateCatRequestDTO)
    case updateCatProfile(id: String, request: UpdateCatProfileRequestDTO)
    case fetchCatFeed(id: String, cursor: String?)
    case deleteCat(id: String)
    case fetchPixelCat(PixelCatRequestDTO)

    var path: String {
        switch self {
        case .fetchCats, .createCat:
            "/cats"
        case let .updateCatProfile(id, _), let .deleteCat(id):
            "/cats/\(id)"
        case let .fetchCatFeed(id, _):
            "/cats/\(id)/feed"
        case .fetchPixelCat:
            "/cats/pixel"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchCats, .fetchCatFeed:
            .get
        case .createCat, .fetchPixelCat:
            .post
        case .updateCatProfile:
            .patch
        case .deleteCat:
            .delete
        }
    }

    var headers: [String: String]? { nil }

    var query: [URLQueryItem]? {
        switch self {
        case let .fetchCatFeed(_, cursor):
            cursor.map { [URLQueryItem(name: "cursor", value: $0)] }
        default:
            nil
        }
    }

    var body: Encodable? {
        switch self {
        case let .createCat(request):
            request
        case let .fetchPixelCat(request):
            request
        case let .updateCatProfile(_, request):
            request
        default:
            nil
        }
    }

    var requiresAuthorization: Bool { true }
}
