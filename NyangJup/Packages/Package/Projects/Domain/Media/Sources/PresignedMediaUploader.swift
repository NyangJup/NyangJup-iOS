//
//  PresignedMediaUploader.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

import Foundation

import CoreNetworkInterface
import DomainMediaInterface

struct PresignedMediaUploader: @unchecked Sendable {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func upload(
        to uploadURL: UploadURL,
        source: PresignedUploadSource,
        mediaType: MediaType
    ) async throws {
        guard let url = URL(string: uploadURL.uploadURL) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.put.rawValue
        request.setValue(contentType(for: mediaType), forHTTPHeaderField: "Content-Type")

        let response: URLResponse
        switch source {
        case let .data(data):
            (_, response) = try await session.upload(for: request, from: data)
        case let .file(fileURL):
            guard fileURL.isFileURL else {
                throw NetworkError.invalidURL
            }
            (_, response) = try await session.upload(for: request, fromFile: fileURL)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.unknown
        }
    }

    private func contentType(for mediaType: MediaType) -> String {
        switch mediaType {
        case .photo:
            "image/jpeg"
        case .video:
            "video/mp4"
        }
    }
}
