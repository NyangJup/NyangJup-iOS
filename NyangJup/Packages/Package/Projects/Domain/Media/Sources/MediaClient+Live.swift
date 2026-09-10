//
//  MediaClient+Live.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

import Foundation

import CoreNetworkInterface
import DomainMediaInterface

public extension MediaClient {
    static func live(
        networkClient: NetworkClient,
        uploadSession: URLSession = .shared
    ) -> Self {
        let uploader = PresignedMediaUploader(session: uploadSession)
        let fetchMedia: @Sendable (String) async throws -> Media = { id in
            let response: MediaResponseDTO = try await networkClient.request(
                MediaEndpoint.fetchMedia(id: id)
            )
            return try response.toEntity()
        }
        let registerMedia: @Sendable (UploadMediaRequestDTO) async throws -> Media = { request in
            let response: UploadMediaResponseDTO = try await networkClient.request(
                MediaEndpoint.uploadMedia(request)
            )
            return try response.toEntity()
        }

        return Self(
            fetchUploadURL: { request in
                let response: UploadURLResponseDTO = try await networkClient.request(
                    MediaEndpoint.fetchUploadURL(request)
                )
                return response.toEntity()
            },
            uploadToPresignedURL: { uploadURL, source, mediaType in
                try await uploader.upload(
                    to: uploadURL,
                    source: source,
                    mediaType: mediaType
                )
            },
            registerMedia: registerMedia,
            uploadVideo: { upload in
                let uploadURLResponse: UploadURLResponseDTO = try await networkClient.request(
                    MediaEndpoint.fetchUploadURL(
                        FetchUploadURLRequestDTO(
                            catId: upload.catID,
                            mediaType: MediaType.video.rawValue
                        )
                    )
                )
                let uploadURL = uploadURLResponse.toEntity()
                try await uploader.upload(
                    to: uploadURL,
                    source: .file(upload.videoURL),
                    mediaType: .video
                )

                guard let thumbnailUploadURL = uploadURL.thumbnailUploadURL,
                      let thumbnailFileName = uploadURL.thumbnailFileName else {
                    throw MediaUploadError.missingThumbnailUploadURL
                }
                try await uploader.upload(
                    to: UploadURL(
                        uploadURL: thumbnailUploadURL,
                        fileName: thumbnailFileName
                    ),
                    source: .data(upload.thumbnailData),
                    mediaType: .photo
                )

                let media = try await registerMedia(
                    UploadMediaRequestDTO(
                        catId: upload.catID,
                        fileName: uploadURL.fileName,
                        thumbnailFileName: thumbnailFileName,
                        mediaType: MediaType.video.rawValue,
                        place: upload.place,
                        comment: upload.comment
                    )
                )
                return try await Self.waitUntilMediaIsReady(
                    media,
                    fetchMedia: fetchMedia
                )
            },
            updateMedia: { id, request in
                let response: UploadMediaResponseDTO = try await networkClient.request(
                    MediaEndpoint.updateMedia(id: id, request: request)
                )
                return try response.toEntity()
            },
            updateComment: { id, comment in
                let response: MediaResponseDTO = try await networkClient.request(
                    MediaEndpoint.updateComment(
                        id: id,
                        request: UpdateMediaCommentRequestDTO(comment: comment)
                    )
                )
                return try response.toEntity()
            },
            fetchMedia: fetchMedia,
            updateIsLiked: { id, isLiked in
                let _: EmptyResponse = try await networkClient.request(
                    MediaEndpoint.updateIsLiked(
                        id: id,
                        request: LikeRequestDTO(isLiked: isLiked)
                    )
                )
            },
            fetchRelayCats: { request in
                let response: FetchRelayCatsResponseDTO = try await networkClient.request(
                    MediaEndpoint.fetchRelayCats(request)
                )
                return try response.toEntity()
            },
            deleteMedia: { id in
                let response: MediaResponseDTO = try await networkClient.request(
                    MediaEndpoint.deleteMedia(id: id)
                )
                return try response.toEntity()
            }
        )
    }
}

private extension MediaClient {
    static func waitUntilMediaIsReady(
        _ media: Media,
        fetchMedia: @escaping @Sendable (String) async throws -> Media
    ) async throws -> Media {
        switch media.processingStatus {
        case .ready:
            return media
        case .failed:
            throw MediaUploadError.processingFailed
        case .processing:
            break
        }

        for attempt in 0..<240 {
            try Task.checkCancellation()
            let fetchedMedia = try await fetchMedia(media.id)
            switch fetchedMedia.processingStatus {
            case .ready:
                return fetchedMedia
            case .failed:
                throw MediaUploadError.processingFailed
            case .processing:
                guard attempt < 239 else { break }
                try await Task.sleep(for: .milliseconds(500))
            }
        }

        throw MediaUploadError.processingTimedOut
    }
}

private enum MediaUploadError: Error {
    case missingThumbnailUploadURL
    case processingFailed
    case processingTimedOut
}
