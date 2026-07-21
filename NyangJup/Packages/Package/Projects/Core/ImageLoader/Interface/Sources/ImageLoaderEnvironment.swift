//
//  ImageLoaderEnvironment.swift
//  NJPackage
//
//  Created by 정지훈 on 7/21/26.
//

import SwiftUI

private struct ImageLoaderClientKey: EnvironmentKey {
    static let defaultValue = ImageLoaderClient(
        loadImage: { _, _, _, _ in
            throw NZImageLoaderError.clientNotConfigured
        }
    )
}

public extension EnvironmentValues {
    var imageLoaderClient: ImageLoaderClient {
        get { self[ImageLoaderClientKey.self] }
        set { self[ImageLoaderClientKey.self] = newValue }
    }
}
