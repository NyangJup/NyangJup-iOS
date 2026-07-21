//
//  File.swift
//  NJPackage
//
//  Created by 정지훈 on 7/21/26.
//

import ImageIO
import UIKit

import CoreImageLoaderInterface

enum ImageDecoder {
    static func downsample(
        data: Data,
        targetSize: CGSize,
        scale: CGFloat
    ) throws -> UIImage {
        guard targetSize.width > 0,
              targetSize.height > 0,
              scale > 0 else {
            throw ImageDecodingError.invalidTargetSize
        }

        let sourceOptions = [
            kCGImageSourceShouldCache: false
        ] as CFDictionary

        guard let source = CGImageSourceCreateWithData(
            data as CFData,
            sourceOptions
        ) else {
            throw ImageDecodingError.sourceCreationFailed
        }

        let maxPixelSize = max(targetSize.width, targetSize.height) * scale

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions
        ) else {
            throw ImageDecodingError.thumbnailCreationFailed
        }

        return UIImage(
            cgImage: cgImage,
            scale: scale,
            orientation: .up
        )
    }
}
