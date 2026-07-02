//
//  MediaClient+Test.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

import DomainMediaInterface

extension MediaClient {
    public static let test = Self(
        networkClient: nil,
        fetchUploadURL: { id in
            UploadURLResponseDTO(
                uploadURL: "https://example.com/uploads/\(id)",
                fileName: "nyangjup-media-\(id).jpg"
            )
        },
        uploadMedia: { _ in },
        updateMedia: { _ in },
        fetchMedia: { id in
            Media(
                id: id,
                thumbnailURL: "https://picsum.photos/200/300",
                mediaType: .photo
            )
        },
        deleteMedia: { id in
            Media(
                id: id,
                thumbnailURL: "https://picsum.photos/200/300",
                mediaType: .photo
            )
        }
    )
}
