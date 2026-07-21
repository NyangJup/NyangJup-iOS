//
//  NZImageLoader.swift
//  NJPackage
//
//  Created by 정지훈 on 7/21/26.
//

import Foundation
import UIKit

import CoreImageLoaderInterface

actor ImageLoader {
    private struct ImageDataResult: Sendable {
        let data: Data
        let source: ImageSource
    }

    private struct LoadedImage: @unchecked Sendable {
        let image: UIImage
        let source: ImageSource
    }

    private struct SendableImage: @unchecked Sendable {
        let image: UIImage
    }

    private struct InFlightRequest {
        let id: UUID
        let task: Task<Data, Error>
    }

    private let memoryCache: MemoryImageCache
    private let diskCache: DiskImageCache
    private let session: URLSession

    private var inFlightRequests: [URL: InFlightRequest] = [:]

    init(
        session: URLSession = URLSession(configuration: .default),
        memoryCache: MemoryImageCache = MemoryImageCache(),
        diskCache: DiskImageCache
    ) {
        self.memoryCache = memoryCache
        self.diskCache = diskCache
        self.session = session
    }

    init(
        maxDiskCacheSize: Int = 300 * 1024 * 1024
    ) throws {
        try self.init(
            diskCache: DiskImageCache(maxSize: maxDiskCacheSize)
        )
    }

    func image(
        for url: URL,
        targetSize: CGSize,
        scale: CGFloat,
        allowedSources: Set<ImageSource> = [.memory, .disk, .network]
    ) async throws -> UIImage {
        guard targetSize.width.isFinite,
              targetSize.height.isFinite,
              scale.isFinite,
              targetSize.width > 0,
              targetSize.height > 0,
              scale > 0 else {
            throw ImageDecodingError.invalidTargetSize
        }

        guard !allowedSources.isEmpty else {
            throw NZImageLoaderError.cacheMiss
        }

        if allowedSources.contains(.memory),
           let cachedImage = memoryCache.image(
               for: url,
               targetSize: targetSize,
               scale: scale
           ) {
            return cachedImage
        }

        let imageDataResult = try await imageData(
            for: url,
            allowedSources: allowedSources
        )

        try Task.checkCancellation()

        let loadedImage: LoadedImage

        do {
            let decodedImage = try await Self.decode(
                data: imageDataResult.data,
                targetSize: targetSize,
                scale: scale
            )

            loadedImage = LoadedImage(
                image: decodedImage.image,
                source: imageDataResult.source
            )
        } catch let decodingError as ImageDecodingError {
            switch decodingError {
            case .invalidTargetSize:
                throw decodingError

            case .sourceCreationFailed, .thumbnailCreationFailed:
                loadedImage = try await recoverImageIfNeeded(
                    from: imageDataResult,
                    url: url,
                    targetSize: targetSize,
                    scale: scale,
                    allowedSources: allowedSources,
                    decodingError: decodingError
                )
            }
        } catch {
            throw error
        }

        try Task.checkCancellation()

        if allowedSources.contains(.memory) {
            memoryCache.insert(
                loadedImage.image,
                for: url,
                targetSize: targetSize,
                scale: scale
            )
        }

        return loadedImage.image
    }

    private func imageData(
        for url: URL,
        allowedSources: Set<ImageSource>
    ) async throws -> ImageDataResult {
        if allowedSources.contains(.disk),
           let cachedData = try await diskCache.data(for: url) {
            return ImageDataResult(
                data: cachedData,
                source: .disk
            )
        }

        guard allowedSources.contains(.network) else {
            throw NZImageLoaderError.cacheMiss
        }

        let downloadedData = try await downloadData(for: url)

        if allowedSources.contains(.disk) {
            try? await diskCache.insert(downloadedData, for: url)
        }

        return ImageDataResult(
            data: downloadedData,
            source: .network
        )
    }

    private func downloadData(for url: URL) async throws -> Data {
        if let existingRequest = inFlightRequests[url] {
            return try await existingRequest.task.value
        }

        let requestID = UUID()
        let session = session

        let task = Task<Data, Error> {
            var request = URLRequest(url: url)
            request.timeoutInterval = 20

            let (data, response) = try await session.data(for: request)

            try Self.validate(
                data: data,
                response: response
            )

            return data
        }

        inFlightRequests[url] = InFlightRequest(
            id: requestID,
            task: task
        )

        do {
            let data = try await task.value
            removeInFlightRequest(for: url, id: requestID)
            return data
        } catch {
            removeInFlightRequest(for: url, id: requestID)
            throw error
        }
    }

    private func recoverImageIfNeeded(
        from result: ImageDataResult,
        url: URL,
        targetSize: CGSize,
        scale: CGFloat,
        allowedSources: Set<ImageSource>,
        decodingError: Error
    ) async throws -> LoadedImage {
        guard result.source == .disk else {
            if allowedSources.contains(.disk) {
                try? await diskCache.removeData(for: url)
            }

            throw decodingError
        }

        try? await diskCache.removeData(for: url)

        guard allowedSources.contains(.network) else {
            throw decodingError
        }

        try Task.checkCancellation()

        let freshData = try await downloadData(for: url)

        if allowedSources.contains(.disk) {
            try? await diskCache.insert(freshData, for: url)
        }

        do {
            let decodedImage = try await Self.decode(
                data: freshData,
                targetSize: targetSize,
                scale: scale
            )

            return LoadedImage(
                image: decodedImage.image,
                source: .network
            )
        } catch {
            if allowedSources.contains(.disk) {
                try? await diskCache.removeData(for: url)
            }

            throw error
        }
    }

    nonisolated private static func decode(
        data: Data,
        targetSize: CGSize,
        scale: CGFloat
    ) async throws -> SendableImage {
        try await Task.detached(priority: .userInitiated) {
            let image = try ImageDecoder.downsample(
                data: data,
                targetSize: targetSize,
                scale: scale
            )

            return SendableImage(image: image)
        }
        .value
    }

    nonisolated private static func validate(
        data: Data,
        response: URLResponse
    ) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw NZImageLoaderError.invalidResponse
        }

        guard !data.isEmpty else {
            throw NZImageLoaderError.emptyData
        }
    }

    private func removeInFlightRequest(
        for url: URL,
        id: UUID
    ) {
        guard inFlightRequests[url]?.id == id else {
            return
        }

        inFlightRequests[url] = nil
    }
}
