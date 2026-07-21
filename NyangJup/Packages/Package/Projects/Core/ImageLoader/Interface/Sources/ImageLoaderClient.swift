//
//  ImageLoaderClient.swift
//  NJPackage
//
//  Created by 정지훈 on 7/21/26.
//

import Foundation
import UIKit

public struct ImageLoaderClient: Sendable {
    public typealias Scale = CGFloat
    public typealias CacheOptions =  Set<ImageSource>
    
    public var loadImage: @Sendable (
        URL,
        CGSize,
        Scale,
        CacheOptions
    ) async throws -> UIImage

    public init(
        loadImage: @escaping @Sendable (
            URL,
            CGSize,
            Scale,
            CacheOptions
        ) async throws -> UIImage
    ) {
        self.loadImage = loadImage
    }
}
