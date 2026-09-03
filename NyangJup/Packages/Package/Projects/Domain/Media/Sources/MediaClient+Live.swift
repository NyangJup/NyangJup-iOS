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
            uploadMedia: { request in
                let response: UploadMediaResponseDTO = try await networkClient.request(
                    MediaEndpoint.uploadMedia(request)
                )
                return try response.toEntity()
            },
            updateMedia: { id, request in
                let response: UploadMediaResponseDTO = try await networkClient.request(
                    MediaEndpoint.updateMedia(id: id, request: request)
                )
                return try response.toEntity()
            },
            fetchMedia: { id in
                let response: MediaResponseDTO = try await networkClient.request(
                    MediaEndpoint.fetchMedia(id: id)
                )
                return try response.toEntity()
            },
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
