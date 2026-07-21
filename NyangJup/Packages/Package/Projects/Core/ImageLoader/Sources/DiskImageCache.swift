//
//  DiskImageCache.swift
//  NJPackage
//
//  Created by 정지훈 on 7/21/26.
//

import CryptoKit
import Foundation

actor DiskImageCache {
    private struct CacheEntry {
        let fileURL: URL
        let fileSize: Int
        let lastAccessDate: Date
    }

    private let fileManager: FileManager
    private let directory: URL
    private let maxSize: Int
    private let expirationInterval: TimeInterval

    init(
        fileManager: FileManager = .default,
        maxSize: Int,
        expirationInterval: TimeInterval = 7 * 24 * 60 * 60
    ) throws {
        self.fileManager = fileManager
        self.maxSize = maxSize
        self.expirationInterval = expirationInterval

        let cachesDirectory = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        self.directory = cachesDirectory.appendingPathComponent(
            "ImageCache",
            isDirectory: true
        )

        try fileManager
            .createDirectory(
                at: self.directory,
                withIntermediateDirectories: true
            )

    }

    func data(for url: URL) throws -> Data? {
        let fileURL = fileURL(for: url)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let attributes = try fileManager.attributesOfItem(
                atPath: fileURL.path
            )

            guard let lastAccessDate = attributes[.modificationDate] as? Date else {
                try? fileManager.removeItem(at: fileURL)
                return nil
            }

            guard !isExpired(lastAccessDate: lastAccessDate) else {
                try? fileManager.removeItem(at: fileURL)
                return nil
            }

            let data = try Data(contentsOf: fileURL, options: .alwaysMapped)

            try? fileManager.setAttributes(
                [.modificationDate: Date()],
                ofItemAtPath: fileURL.path
            )

            return data
        } catch {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
    }

    func insert(_ data: Data, for url: URL) throws {
        guard !data.isEmpty, data.count <= maxSize else { return }

        let fileURL = fileURL(for: url)

        try data.write(to: fileURL, options: .atomic)

        try fileManager.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: fileURL.path
        )

        try trimIfNeeded()
    }

    func removeData(for url: URL) throws {
        let fileURL = fileURL(for: url)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        try fileManager.removeItem(at: fileURL)
    }

    private func fileURL(for url: URL) -> URL {
        let urlData = Data(url.absoluteString.utf8)
        let digest = SHA256.hash(data: urlData)

        let fileName = digest
            .map { String(format: "%02x", $0) }
            .joined()

        return directory.appending(path: fileName)
    }

    private func isExpired(
        lastAccessDate: Date,
        now: Date = Date()
    ) -> Bool {
        now.timeIntervalSince(lastAccessDate) > expirationInterval
    }

    private func trimIfNeeded() throws {
        let resourceKeys: Set<URLResourceKey> = [
            .isRegularFileKey,
            .fileSizeKey,
            .contentModificationDateKey
        ]

        let fileURLs = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: Array(resourceKeys),
            options: .skipsHiddenFiles
        )

        let now = Date()

        var validEntries: [CacheEntry] = []

        for fileURL in fileURLs {
            guard let values = try? fileURL.resourceValues(
                forKeys: resourceKeys
            ) else { continue }

            guard values.isRegularFile == true  else { continue }
            let lastAccessDate =
            values.contentModificationDate ?? .distantPast

            if isExpired(
                lastAccessDate: lastAccessDate,
                now: now
            ) {
                try? fileManager.removeItem(at: fileURL)
                continue
            }

            validEntries.append(
                CacheEntry(
                    fileURL: fileURL,
                    fileSize: values.fileSize ?? 0,
                    lastAccessDate: lastAccessDate
                )
            )
        }

        var currentSize = validEntries.reduce(0) {
            $0 + $1.fileSize
        }

        guard currentSize > maxSize else {
            return
        }

        let oldestEntries = validEntries.sorted {
            $0.lastAccessDate < $1.lastAccessDate
        }

        for entry in oldestEntries {
            try? fileManager.removeItem(at: entry.fileURL)
            currentSize -= entry.fileSize

            if currentSize <= maxSize {
                break
            }
        }
    }
}
