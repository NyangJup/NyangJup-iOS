//
//  FeedItem.swift
//  NJPackage
//
//  Created by 정지훈 on 9/8/26.
//

import Foundation

import DomainMediaInterface

enum FeedItem: Identifiable {
    case uploading(UUID)
    case media(Media)

    var id: String {
        switch self {
        case let .uploading(id): "upload-\(id.uuidString)"
        case let .media(media): media.id
        }
    }

    var media: Media? {
        guard case let .media(media) = self else { return nil }
        return media
    }

    var uploadID: UUID? {
        guard case let .uploading(id) = self else { return nil }
        return id
    }
}
