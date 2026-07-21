//
//  ImageLoaderClient+Live.swift
//  NJPackage
//
//  Created by 정지훈 on 7/21/26.
//

import CoreImageLoaderInterface

public extension ImageLoaderClient {
    static func live(
        maxDiskCacheSize: Int = 300 * 1024 * 1024
    ) throws -> Self {
        let loader = try ImageLoader(
            maxDiskCacheSize: maxDiskCacheSize
        )

        return Self(
            loadImage: { url, targetSize, scale, allowedSources in
                try await loader.image(
                    for: url,
                    targetSize: targetSize,
                    scale: scale,
                    allowedSources: allowedSources
                )
            }
        )
    }
}
