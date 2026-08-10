//
//  NativeAdItem.swift
//  NJPackage
//
//  Created by 정지훈 on 8/7/26.
//

import Foundation

/// SDK의 NativeAd를 Interface 레이어에 노출하지 않기 위한 박스.
/// object의 실제 타입은 CoreAds 구현부만 안다.
///
/// 담긴 광고 객체는 로드·렌더링 모두 @MainActor에서만 다루므로
/// @unchecked Sendable로 표시한다.
public struct NativeAdItem: Identifiable, @unchecked Sendable {
    public let id: String
    public let object: AnyObject

    public init(
        id: String = UUID().uuidString,
        object: AnyObject
    ) {
        self.id = id
        self.object = object
    }

}
