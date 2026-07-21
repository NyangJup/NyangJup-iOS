//
//  ImageCacheResult.swift
//  NJPackage
//
//  Created by 정지훈 on 7/21/26.
//

import UIKit

public struct ImageCacheResult: @unchecked Sendable {
    public let image: UIImage
    public let source: ImageSource

    public init(
        image: UIImage,
        source: ImageSource
    ) {
        self.image = image
        self.source = source
    }
}
