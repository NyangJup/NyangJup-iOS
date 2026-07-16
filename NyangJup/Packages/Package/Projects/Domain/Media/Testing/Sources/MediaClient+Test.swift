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
        },
        fetchFeeds: { _, cursor in
            switch cursor {
            case nil:
                FeedPage(
                    items: [
                        Media(
                            id: "feed-photo-1",
                            thumbnailURL: "https://picsum.photos/id/237/600/800",
                            mediaType: .photo
                        ),
                        Media(
                            id: "feed-video-1",
                            thumbnailURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
                            mediaType: .video
                        ),
                        Media(
                            id: "feed-photo-2",
                            thumbnailURL: "https://picsum.photos/id/40/600/800",
                            mediaType: .photo
                        ),
                        Media(
                            id: "feed-video-2",
                            thumbnailURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
                            mediaType: .video
                        ),
                        Media(
                            id: "feed-photo-3",
                            thumbnailURL: "https://picsum.photos/id/1025/600/800",
                            mediaType: .photo
                        ),
                        Media(
                            id: "feed-video-3",
                            thumbnailURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
                            mediaType: .video
                        ),
                        Media(
                            id: "feed-photo-6",
                            thumbnailURL: "https://picsum.photos/id/433/600/800",
                            mediaType: .photo
                        ),
                        Media(
                            id: "feed-video-6",
                            thumbnailURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
                            mediaType: .video
                        ),
                        Media(
                            id: "feed-photo-7",
                            thumbnailURL: "https://picsum.photos/id/593/600/800",
                            mediaType: .photo
                        ),
                        Media(
                            id: "feed-video-7",
                            thumbnailURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
                            mediaType: .video
                        )
                    ],
                    nextCursor: "feed-page-2"
                )

            case "feed-page-2":
                FeedPage(
                    items: [
                        Media(
                            id: "feed-photo-4",
                            thumbnailURL: "https://picsum.photos/id/1074/600/800",
                            mediaType: .photo
                        ),
                        Media(
                            id: "feed-video-4",
                            thumbnailURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
                            mediaType: .video
                        ),
                        Media(
                            id: "feed-photo-5",
                            thumbnailURL: "https://picsum.photos/id/219/600/800",
                            mediaType: .photo
                        ),
                        Media(
                            id: "feed-video-5",
                            thumbnailURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
                            mediaType: .video
                        ),
                        Media(
                            id: "feed-photo-8",
                            thumbnailURL: "https://picsum.photos/id/577/600/800",
                            mediaType: .photo
                        ),
                        Media(
                            id: "feed-video-8",
                            thumbnailURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
                            mediaType: .video
                        ),
                        Media(
                            id: "feed-photo-9",
                            thumbnailURL: "https://picsum.photos/id/659/600/800",
                            mediaType: .photo
                        ),
                        Media(
                            id: "feed-video-9",
                            thumbnailURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4",
                            mediaType: .video
                        ),
                        Media(
                            id: "feed-photo-10",
                            thumbnailURL: "https://picsum.photos/id/718/600/800",
                            mediaType: .photo
                        ),
                        Media(
                            id: "feed-video-10",
                            thumbnailURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4",
                            mediaType: .video
                        )
                    ],
                    nextCursor: nil
                )

            default:
                FeedPage(items: [], nextCursor: nil)
            }
        }
    )
}
