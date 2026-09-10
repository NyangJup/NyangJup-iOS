//
//  VideoTrimClient.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import AVFoundation
import Foundation
import UIKit

import CoreVideoInterface

public extension VideoTrimClient {
    static var live: Self {
        Self(
            loadDuration: { try await Self.loadDuration(from: $0) },
            generateThumbnails: {
                try await Self.generateThumbnails(from: $0, duration: $1, count: $2)
            },
            exportTrimmedVideo: {
                try await Self.exportTrimmedVideo(
                    sourceURL: $0,
                    startTime: $1,
                    endTime: $2
                )
            },
            generateUploadThumbnail: {
                try await Self.generateUploadThumbnail(from: $0, at: $1)
            }
        )
    }

    private static func loadDuration(from url: URL) async throws -> Double {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        return duration.seconds
    }
    
    private static func generateThumbnails(
        from url: URL,
        duration: Double,
        count: Int
    ) async throws -> [UIImage] {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = .init(width: 100, height: 100)
        
        var images: [UIImage] = []
        
        for index in 0..<count {
            let seconds = duration * Double(index) / Double(count)
            let time = CMTime(seconds: seconds, preferredTimescale: 600)
            let result = try await generator.image(at: time)
            let image = UIImage(cgImage: result.image)
            images.append(image)
        }
        
        return images
    }
    
    private static func exportTrimmedVideo(
        sourceURL: URL,
        startTime: Double,
        endTime: Double
    ) async throws -> URL {
        let encodingTask = Task.detached(priority: .userInitiated) {
            try await Self.encodeTrimmedVideo(
                sourceURL: sourceURL,
                startTime: startTime,
                endTime: endTime
            )
        }

        return try await withTaskCancellationHandler {
            try await encodingTask.value
        } onCancel: {
            encodingTask.cancel()
        }
    }

    private static func generateUploadThumbnail(
        from url: URL,
        at seconds: Double
    ) async throws -> Data {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 640, height: 640)

        let result = try await generator.image(
            at: CMTime(seconds: seconds, preferredTimescale: 600)
        )
        let image = UIImage(cgImage: result.image)
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw VideoTrimError.thumbnailEncodingFailed
        }
        return data
    }

    static func videoOutputSettings(
        renderSize: CGSize,
        frameRate: Float
    ) -> [String: Any] {
        [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(renderSize.width),
            AVVideoHeightKey: Int(renderSize.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6_000_000,
                AVVideoExpectedSourceFrameRateKey: Int(frameRate.rounded()),
                AVVideoMaxKeyFrameIntervalDurationKey: 1,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
    }

    private static func encodeTrimmedVideo(
        sourceURL: URL,
        startTime: Double,
        endTime: Double
    ) async throws -> URL {
        let asset = AVURLAsset(url: sourceURL)
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoTrimError.cannotCreateExportSession
        }

        let duration = try await asset.load(.duration)
        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let nominalFrameRate = try await videoTrack.load(.nominalFrameRate)
        let frameRate = min(max(nominalFrameRate, 1), 60)
        let renderConfiguration = makeRenderConfiguration(
            naturalSize: naturalSize,
            preferredTransform: preferredTransform
        )
        let videoComposition = makeVideoComposition(
            videoTrack: videoTrack,
            assetDuration: duration,
            renderConfiguration: renderConfiguration,
            frameRate: frameRate
        )

        let reader = try AVAssetReader(asset: asset)
        reader.timeRange = CMTimeRange(
            start: CMTime(seconds: startTime, preferredTimescale: 600),
            end: CMTime(seconds: endTime, preferredTimescale: 600)
        )

        let videoOutput = AVAssetReaderVideoCompositionOutput(
            videoTracks: [videoTrack],
            videoSettings: [
                kCVPixelBufferPixelFormatTypeKey as String:
                    kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            ]
        )
        videoOutput.videoComposition = videoComposition
        guard reader.canAdd(videoOutput) else {
            throw VideoTrimError.cannotCreateExportSession
        }
        reader.add(videoOutput)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        writer.shouldOptimizeForNetworkUse = true

        let videoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: videoOutputSettings(
                renderSize: renderConfiguration.renderSize,
                frameRate: frameRate
            )
        )
        guard writer.canAdd(videoInput) else {
            throw VideoTrimError.cannotCreateExportSession
        }
        writer.add(videoInput)

        var audioOutput: AVAssetReaderTrackOutput?
        var audioInput: AVAssetWriterInput?
        if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
            let output = AVAssetReaderTrackOutput(
                track: audioTrack,
                outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM]
            )
            let input = AVAssetWriterInput(
                mediaType: .audio,
                outputSettings: [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVEncoderBitRateKey: 128_000,
                    AVSampleRateKey: 48_000,
                    AVNumberOfChannelsKey: 2
                ]
            )
            guard reader.canAdd(output), writer.canAdd(input) else {
                throw VideoTrimError.cannotCreateExportSession
            }
            reader.add(output)
            writer.add(input)
            audioOutput = output
            audioInput = input
        }

        guard writer.startWriting(), reader.startReading() else {
            throw writer.error ?? reader.error ?? VideoTrimError.exportFailed
        }
        writer.startSession(atSourceTime: reader.timeRange.start)

        do {
            try await copySamples(
                reader: reader,
                writer: writer,
                videoOutput: videoOutput,
                videoInput: videoInput,
                audioOutput: audioOutput,
                audioInput: audioInput
            )
            await writer.finishWriting()
            guard writer.status == .completed else {
                throw writer.error ?? VideoTrimError.exportFailed
            }
            return outputURL
        } catch {
            reader.cancelReading()
            writer.cancelWriting()
            try? FileManager.default.removeItem(at: outputURL)
            throw error
        }
    }

    private static func copySamples(
        reader: AVAssetReader,
        writer: AVAssetWriter,
        videoOutput: AVAssetReaderOutput,
        videoInput: AVAssetWriterInput,
        audioOutput: AVAssetReaderOutput?,
        audioInput: AVAssetWriterInput?
    ) async throws {
        var isVideoFinished = false
        var isAudioFinished = audioOutput == nil

        while !isVideoFinished || !isAudioFinished {
            try Task.checkCancellation()
            var didAppendSample = false

            if !isVideoFinished, videoInput.isReadyForMoreMediaData {
                if let sample = videoOutput.copyNextSampleBuffer() {
                    guard videoInput.append(sample) else {
                        throw writer.error ?? VideoTrimError.exportFailed
                    }
                    didAppendSample = true
                } else {
                    videoInput.markAsFinished()
                    isVideoFinished = true
                }
            }

            if !isAudioFinished,
               let audioOutput,
               let audioInput,
               audioInput.isReadyForMoreMediaData {
                if let sample = audioOutput.copyNextSampleBuffer() {
                    guard audioInput.append(sample) else {
                        throw writer.error ?? VideoTrimError.exportFailed
                    }
                    didAppendSample = true
                } else {
                    audioInput.markAsFinished()
                    isAudioFinished = true
                }
            }

            if reader.status == .failed {
                throw reader.error ?? VideoTrimError.exportFailed
            }
            if writer.status == .failed {
                throw writer.error ?? VideoTrimError.exportFailed
            }
            if !didAppendSample, (!isVideoFinished || !isAudioFinished) {
                try await Task.sleep(for: .milliseconds(1))
            }
        }
    }

    private static func makeRenderConfiguration(
        naturalSize: CGSize,
        preferredTransform: CGAffineTransform
    ) -> RenderConfiguration {
        let transformedRect = CGRect(origin: .zero, size: naturalSize)
            .applying(preferredTransform)
        let orientedSize = CGSize(
            width: abs(transformedRect.width),
            height: abs(transformedRect.height)
        )
        let isPortrait = orientedSize.height > orientedSize.width
        let bounds = isPortrait
            ? CGSize(width: 1080, height: 1920)
            : CGSize(width: 1920, height: 1080)
        let scale = min(
            1,
            min(bounds.width / orientedSize.width, bounds.height / orientedSize.height)
        )
        let renderSize = CGSize(
            width: even(orientedSize.width * scale),
            height: even(orientedSize.height * scale)
        )
        let transform = preferredTransform
            .concatenating(CGAffineTransform(
                translationX: -transformedRect.minX,
                y: -transformedRect.minY
            ))
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))

        return RenderConfiguration(renderSize: renderSize, transform: transform)
    }

    private static func makeVideoComposition(
        videoTrack: AVAssetTrack,
        assetDuration: CMTime,
        renderConfiguration: RenderConfiguration,
        frameRate: Float
    ) -> AVMutableVideoComposition {
        let composition = AVMutableVideoComposition()
        composition.renderSize = renderConfiguration.renderSize
        composition.frameDuration = CMTime(
            seconds: 1 / Double(frameRate),
            preferredTimescale: 60_000
        )

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: assetDuration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(
            assetTrack: videoTrack
        )
        layerInstruction.setTransform(renderConfiguration.transform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]
        return composition
    }

    private static func even(_ value: CGFloat) -> CGFloat {
        max(2, (value / 2).rounded(.down) * 2)
    }

    private struct RenderConfiguration {
        let renderSize: CGSize
        let transform: CGAffineTransform
    }
}
