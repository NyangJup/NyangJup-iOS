//
//  MediaClient+Test.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

import DomainMediaInterface

private let testFeedItems: [Media] = [
    Media(
        id: "feed-photo-1",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/id/237/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/237/600/800"
    ),
    Media(
        id: "feed-video-1",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/seed/feed-video-1/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/sintel/trailer.mp4"
    ),
    Media(
        id: "feed-photo-2",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/id/40/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/40/600/800"
    ),
    Media(
        id: "feed-video-2",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/seed/feed-video-2/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/bunny/trailer.mp4"
    ),
    Media(
        id: "feed-photo-3",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/id/1025/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/1025/600/800"
    ),
    Media(
        id: "feed-video-3",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/seed/feed-video-3/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/video/movie_300.mp4"
    ),
    Media(
        id: "feed-photo-6",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/id/433/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/433/600/800"
    ),
    Media(
        id: "feed-video-6",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/seed/feed-video-6/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/sintel/trailer.mp4"
    ),
    Media(
        id: "feed-photo-7",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/id/593/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/593/600/800"
    ),
    Media(
        id: "feed-video-7",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/seed/feed-video-7/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/bunny/trailer.mp4"
    ),
    Media(
        id: "feed-photo-4",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/id/1074/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/1074/600/800"
    ),
    Media(
        id: "feed-video-4",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/seed/feed-video-4/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/video/movie_300.mp4"
    ),
    Media(
        id: "feed-photo-5",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/id/219/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/219/600/800"
    ),
    Media(
        id: "feed-video-5",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/seed/feed-video-5/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/sintel/trailer.mp4"
    ),
    Media(
        id: "feed-photo-8",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/id/577/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/577/600/800"
    ),
    Media(
        id: "feed-video-8",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/seed/feed-video-8/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/bunny/trailer.mp4"
    ),
    Media(
        id: "feed-photo-9",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/id/659/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/659/600/800"
    ),
    Media(
        id: "feed-video-9",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/seed/feed-video-9/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/video/movie_300.mp4"
    ),
    Media(
        id: "feed-photo-10",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/id/718/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/718/600/800"
    ),
    Media(
        id: "feed-video-10",
        catId: "cat-1",
        userId: "test-user-id",
        comment: "오늘도 냥냥한 하루!",
        thumbnailURL: "https://picsum.photos/seed/feed-video-10/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/sintel/trailer.mp4"
    )
]

extension MediaClient {
    public static let test = Self(
        fetchUploadURL: { request in
            let fileExtension = switch request.mediaType {
            case "PHOTO": "jpg"
            case "VIDEO": "mov"
            default: "bin"
            }
            let fileName = "nyangjup-media-\(request.catId ?? "common").\(fileExtension)"

            return UploadURL(
                uploadURL: "https://example.com/uploads/\(fileName)",
                fileName: fileName
            )
        },
        uploadToPresignedURL: { _, _, _ in },
        uploadMedia: { request in
            Media(
                id: "test-media-id",
                catId: request.catId,
                userId: "test-user-id",
                comment: request.comment,
                thumbnailURL: "https://example.com/thumbnails/\(request.fileName).jpg",
                mediaType: MediaType(rawValue: request.mediaType) ?? .photo,
                mediaURL: "https://example.com/media/\(request.fileName)"
            )
        },
        updateMedia: { id, request in
            Media(
                id: id,
                catId: request.catId,
                userId: "test-user-id",
                comment: request.comment,
                thumbnailURL: "https://example.com/thumbnails/\(request.fileName).jpg",
                mediaType: MediaType(rawValue: request.mediaType) ?? .photo,
                mediaURL: "https://example.com/media/\(request.fileName)"
            )
        },
        fetchMedia: { id in
            testFeedItems.first(where: { $0.id == id }) ?? testFeedItems[0]
        },
        updateIsLiked: { _, _ in },
        fetchRelayCats: { request in
            guard let anchorIndex = testFeedItems.firstIndex(where: {
                $0.id == request.anchorId
            }) else {
                return RelayPage(
                    items: [],
                    anchorIndex: 0,
                    previousCursor: nil,
                    nextCursor: nil
                )
            }

            let lowerBound = max(0, anchorIndex - request.beforeCount)
            let upperBound = min(
                testFeedItems.count,
                anchorIndex + request.afterCount + 1
            )
            let items = testFeedItems[lowerBound..<upperBound].map { media in
                RelayCat(
                    mediaId: media.id,
                    catId: request.catId,
                    userId: "test-user-id",
                    comment: "오늘도 냥냥한 하루!",
                    place: "서울",
                    thumbnailURL: media.thumbnailURL ?? "",
                    name: "나비",
                    catImageURL: "https://example.com/cat.png",
                    mediaType: media.mediaType,
                    mediaURL: media.mediaURL ?? "",
                    isLiked: false
                )
            }

            return RelayPage(
                items: Array(items),
                anchorIndex: anchorIndex - lowerBound,
                previousCursor: lowerBound > 0 ? String(lowerBound) : nil,
                nextCursor: upperBound < testFeedItems.count ? String(upperBound) : nil
            )
        },
        deleteMedia: { id in
            Media(
                id: id,
                catId: "cat-1",
                userId: "test-user-id",
                comment: "",
                thumbnailURL: "https://picsum.photos/200/300",
                mediaType: .photo,
                mediaURL: "https://picsum.photos/200/300"
            )
        }
    )
}
