//
//  RelayCatFeedItem.swift
//  NJPackage
//
//  Created by 정지훈 on 8/7/26.
//

import Foundation

import CoreAdsInterface
import DomainMediaInterface

enum RelayCatFeedItem: Identifiable {
    case relay(RelayCat)
    case ad(NativeAdItem)

    var id: String {
        switch self {
        case let .relay(item): item.mediaId
        case let .ad(item): "ad-\(item.id)"
        }
    }
}
