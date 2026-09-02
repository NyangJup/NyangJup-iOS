//
//  MediaEndpoint.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

import Foundation

import CoreNetworkInterface
import DomainMediaInterface

enum MediaEndpoint: Endpoint {
    case fetchUploadURL(FetchUploadURLRequestDTO)
    case uploadMedia(UploadMediaRequestDTO)
    case updateMedia(id: String, request: UploadMediaRequestDTO)
    case fetchMedia(id: String)
    case updateIsLiked(id: String, request: LikeRequestDTO)
    case fetchRelayCats(FetchRelayCatsRequestDTO)
    case deleteMedia(id: String)

    var path: String {
        switch self {
        case .fetchUploadURL:
            "/media/upload-urls"
        case .uploadMedia:
            "/media"
        case let .updateMedia(id, _), let .fetchMedia(id), let .deleteMedia(id):
            "/media/\(id)"
        case let .updateIsLiked(id, _):
            "/media/\(id)/like"
        case .fetchRelayCats:
            "/media/relay"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchUploadURL, .uploadMedia:
            .post
        case .updateMedia, .updateIsLiked:
            .put
        case .fetchMedia, .fetchRelayCats:
            .get
        case .deleteMedia:
            .delete
        }
    }

    var headers: [String: String]? { nil }

    var query: [URLQueryItem]? {
        switch self {
        case let .fetchRelayCats(request):
            [
                URLQueryItem(name: "anchorId", value: request.anchorId),
                URLQueryItem(name: "catId", value: request.catId),
                URLQueryItem(name: "beforeCount", value: String(request.beforeCount)),
                URLQueryItem(name: "afterCount", value: String(request.afterCount))
            ]
        default:
            nil
        }
    }

    var body: Encodable? {
        switch self {
        case let .fetchUploadURL(request):
            request
        case let .uploadMedia(request), let .updateMedia(_, request):
            request
        case let .updateIsLiked(_, request):
            request
        default:
            nil
        }
    }

    var requiresAuthorization: Bool { true }
}
