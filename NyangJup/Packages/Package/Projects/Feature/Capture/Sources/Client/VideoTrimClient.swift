//
//  VideoTrimClient.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import UIKit
import AVFoundation

public enum VideoTrimError: Error {
    case cannotCreateExportSession
    case exportFailed
}

public struct VideoTrimClient {
    func loadDuration(from url: URL) async throws -> Double {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        return duration.seconds
    }
    
    func generateThumbnails(
        from url: URL,
        count: Int
    ) async throws -> [UIImage] {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let totalSeconds = duration.seconds
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = .init(width: 100, height: 100)
        
        var images: [UIImage] = []
        
        for index in 0..<count {
            let seconds = totalSeconds * Double(index) / Double(count)
            let time = CMTime(seconds: seconds, preferredTimescale: 600)
            let result = try await generator.image(at: time)
            let image = UIImage(cgImage: result.image)
            images.append(image)
        }
        
        return images
    }
    
    func exportTrimmedVideo(
        sourceURL: URL,
        startTime: Double,
        endTime: Double
    ) async throws -> URL {
        let asset = AVURLAsset(url: sourceURL)
        
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw VideoTrimError.cannotCreateExportSession
        }
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        
        let trimmedRange = CMTimeRange(
            start: CMTime(seconds: startTime, preferredTimescale: 600),
            end: CMTime(seconds: endTime, preferredTimescale: 600)
        )
        
        exportSession.timeRange = trimmedRange
        
        try await exportSession.export(to: outputURL, as: .mov)
        
        return outputURL
    }
}
