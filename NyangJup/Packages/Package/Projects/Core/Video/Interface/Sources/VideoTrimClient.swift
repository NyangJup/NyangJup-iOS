//
//  VideoTrimClient.swift
//  NJPackage
//
//  Created by 정지훈 on 9/7/26.
//

import Foundation
import UIKit

public enum VideoTrimError: Error {
    case cannotCreateExportSession
    case exportFailed
    case thumbnailEncodingFailed
}

@MainActor
public struct VideoTrimClient: Sendable {
    private let loadDurationOperation: @Sendable (URL) async throws -> Double
    private let generateThumbnailsOperation: @Sendable (URL, Double, Int) async throws -> [UIImage]
    private let exportTrimmedVideoOperation: @Sendable (URL, Double, Double) async throws -> URL
    private let generateUploadThumbnailOperation: @Sendable (URL, Double) async throws -> Data

    public init(
        loadDuration: @escaping @Sendable (URL) async throws -> Double,
        generateThumbnails: @escaping @Sendable (URL, Double, Int) async throws -> [UIImage],
        exportTrimmedVideo: @escaping @Sendable (URL, Double, Double) async throws -> URL,
        generateUploadThumbnail: @escaping @Sendable (URL, Double) async throws -> Data
    ) {
        self.loadDurationOperation = loadDuration
        self.generateThumbnailsOperation = generateThumbnails
        self.exportTrimmedVideoOperation = exportTrimmedVideo
        self.generateUploadThumbnailOperation = generateUploadThumbnail
    }

    public init() {
        self.init(
            loadDuration: { _ in throw CancellationError() },
            generateThumbnails: { _, _, _ in throw CancellationError() },
            exportTrimmedVideo: { _, _, _ in throw CancellationError() },
            generateUploadThumbnail: { _, _ in throw CancellationError() }
        )
    }

    public func loadDuration(from url: URL) async throws -> Double {
        try await loadDurationOperation(url)
    }

    public func generateThumbnails(
        from url: URL,
        duration: Double,
        count: Int
    ) async throws -> [UIImage] {
        try await generateThumbnailsOperation(url, duration, count)
    }

    public func exportTrimmedVideo(
        sourceURL: URL,
        startTime: Double,
        endTime: Double
    ) async throws -> URL {
        try await exportTrimmedVideoOperation(sourceURL, startTime, endTime)
    }

    public func generateUploadThumbnail(from url: URL, at seconds: Double) async throws -> Data {
        try await generateUploadThumbnailOperation(url, seconds)
    }
}
