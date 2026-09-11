//
//  AdsClient+Test.swift
//  NJPackage
//
//  Created by 정지훈 on 9/11/26.
//

import SwiftUI

import CoreAdsInterface

public extension AdsClient {
    static let test = Self(
        setup: {},
        loadRewardAds: {},
        showRewardAds: { false },
        loadNativeAds: { _ in [] }
    )
}

public extension NativeAdFactory {
    static let test = Self { _ in
        AnyView(
            ContentUnavailableView(
                "NativeAd 테스트 대역",
                systemImage: "rectangle.badge.person.crop"
            )
        )
    }
}
