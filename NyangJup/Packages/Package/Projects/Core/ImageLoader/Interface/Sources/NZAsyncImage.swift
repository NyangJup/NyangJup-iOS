//
//  NZAsyncImage.swift
//  NJPackage
//
//  Created by 정지훈 on 7/21/26.
//

import SwiftUI
import UIKit

public struct NZAsyncImage<Content: View, Placeholder: View>: View {
    private struct LoadID: Hashable {
        let url: URL
        let targetSize: CGSize
        let scale: CGFloat
        let options: ImageLoaderClient.CacheOptions
    }

    private let url: URL
    private let targetSize: CGSize
    private let options: ImageLoaderClient.CacheOptions
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @Environment(\.displayScale) private var displayScale
    @Environment(\.imageLoaderClient) private var imageLoaderClient

    @State private var image: UIImage?

    private var loadID: LoadID {
        LoadID(
            url: url,
            targetSize: targetSize,
            scale: displayScale,
            options: options
        )
    }

    public init(
        url: URL,
        targetSize: CGSize,
        options: ImageLoaderClient.CacheOptions = [.memory, .disk, .network],
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.targetSize = targetSize
        self.options = options
        self.content = content
        self.placeholder = placeholder
    }

    public init(
        url: URL,
        targetSize: CGSize,
        options: ImageLoaderClient.CacheOptions = [.memory, .disk, .network],
        @ViewBuilder content: @escaping (Image) -> Content
    ) where Placeholder == EmptyView {
        self.init(
            url: url,
            targetSize: targetSize,
            options: options,
            content: content,
            placeholder: { EmptyView() }
        )
    }

    public var body: some View {
        Group {
            if let image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .task(id: loadID) {
            image = nil

            let loadedImage = try? await imageLoaderClient.loadImage(
                url,
                targetSize,
                displayScale,
                options
            )

            guard !Task.isCancelled else { return }
            image = loadedImage
        }
    }
}
