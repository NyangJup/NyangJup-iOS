//
//  File.swift
//  NJPackage
//
//  Created by 정지훈 on 8/7/26.
//

import SwiftUI

import CoreAdsInterface

public extension NativeAdFactory {
    static let live: NativeAdFactory = {
        NativeAdFactory { item in
            AnyView(NativeAdContentView(item: item))
        }
    }()
}
