//
//  File.swift
//  NJPackage
//
//  Created by 정지훈 on 7/21/26.
//

import UIKit
final class MemoryImageCache {
    private let cache = NSCache<NSString, UIImage>()

    func image(
        for url: URL,
        targetSize: CGSize,
        scale: CGFloat
    ) -> UIImage? {
        let key = cacheKey(
            url: url,
            targetSize: targetSize,
            scale: scale
        )

        return cache.object(forKey: key)
    }

    func insert(
        _ image: UIImage,
        for url: URL,
        targetSize: CGSize,
        scale: CGFloat
    ) {
        let key = cacheKey(
            url: url,
            targetSize: targetSize,
            scale: scale
        )

        let cost = memoryCost(of: image)

        cache.setObject(
            image,
            forKey: key,
            cost: cost
        )
    }

    private func cacheKey(
        url: URL,
        targetSize: CGSize,
        scale: CGFloat
    ) -> NSString {
        let pixelWidth = Int(ceil(targetSize.width * scale))
        let pixelHeight = Int(ceil(targetSize.height * scale))

        return [
            url.absoluteString,
            "\(pixelWidth)x\(pixelHeight)",
            "scale:\(scale)"
        ]
            .joined(separator: "|") as NSString
    }

    private func memoryCost(
        of image: UIImage
    ) -> Int {
        guard let cgImage = image.cgImage else {
            let pixelWidth = image.size.width * image.scale
            let pixelHeight = image.size.height * image.scale

            return Int(
                pixelWidth * pixelHeight * 4
            )
        }

        return cgImage.bytesPerRow * cgImage.height
    }
}
