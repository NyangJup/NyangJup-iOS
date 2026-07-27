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
        thumbnailURL: "https://picsum.photos/id/237/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/237/600/800"
    ),
    Media(
        id: "feed-video-1",
        thumbnailURL: "https://picsum.photos/seed/feed-video-1/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/sintel/trailer.mp4"
    ),
    Media(
        id: "feed-photo-2",
        thumbnailURL: "https://picsum.photos/id/40/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/40/600/800"
    ),
    Media(
        id: "feed-video-2",
        thumbnailURL: "https://picsum.photos/seed/feed-video-2/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/bunny/trailer.mp4"
    ),
    Media(
        id: "feed-photo-3",
        thumbnailURL: "https://picsum.photos/id/1025/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/1025/600/800"
    ),
    Media(
        id: "feed-video-3",
        thumbnailURL: "https://picsum.photos/seed/feed-video-3/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/video/movie_300.mp4"
    ),
    Media(
        id: "feed-photo-6",
        thumbnailURL: "https://picsum.photos/id/433/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/433/600/800"
    ),
    Media(
        id: "feed-video-6",
        thumbnailURL: "https://picsum.photos/seed/feed-video-6/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/sintel/trailer.mp4"
    ),
    Media(
        id: "feed-photo-7",
        thumbnailURL: "https://picsum.photos/id/593/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/593/600/800"
    ),
    Media(
        id: "feed-video-7",
        thumbnailURL: "https://picsum.photos/seed/feed-video-7/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/bunny/trailer.mp4"
    ),
    Media(
        id: "feed-photo-4",
        thumbnailURL: "https://picsum.photos/id/1074/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/1074/600/800"
    ),
    Media(
        id: "feed-video-4",
        thumbnailURL: "https://picsum.photos/seed/feed-video-4/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/video/movie_300.mp4"
    ),
    Media(
        id: "feed-photo-5",
        thumbnailURL: "https://picsum.photos/id/219/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/219/600/800"
    ),
    Media(
        id: "feed-video-5",
        thumbnailURL: "https://picsum.photos/seed/feed-video-5/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/sintel/trailer.mp4"
    ),
    Media(
        id: "feed-photo-8",
        thumbnailURL: "https://picsum.photos/id/577/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/577/600/800"
    ),
    Media(
        id: "feed-video-8",
        thumbnailURL: "https://picsum.photos/seed/feed-video-8/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/bunny/trailer.mp4"
    ),
    Media(
        id: "feed-photo-9",
        thumbnailURL: "https://picsum.photos/id/659/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/659/600/800"
    ),
    Media(
        id: "feed-video-9",
        thumbnailURL: "https://picsum.photos/seed/feed-video-9/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/video/movie_300.mp4"
    ),
    Media(
        id: "feed-photo-10",
        thumbnailURL: "https://picsum.photos/id/718/600/800",
        mediaType: .photo,
        mediaURL: "https://picsum.photos/id/718/600/800"
    ),
    Media(
        id: "feed-video-10",
        thumbnailURL: "https://picsum.photos/seed/feed-video-10/600/800",
        mediaType: .video,
        mediaURL: "https://media.w3.org/2010/05/sintel/trailer.mp4"
    )
]

private func testFeedPage(cursor: String?) -> FeedPage {
    switch cursor {
    case nil:
        FeedPage(
            items: Array(testFeedItems.prefix(10)),
            nextCursor: "feed-page-2"
        )

    case "feed-page-2":
        FeedPage(
            items: Array(testFeedItems.dropFirst(10)),
            nextCursor: nil
        )

    default:
        FeedPage(items: [], nextCursor: nil)
    }
}

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
            testFeedItems.first(where: { $0.id == id }) ?? testFeedItems[0]
        },
        updateIsLiked: { _, _ in },
        fetchRelayCats: { request in
            guard let anchorIndex = testFeedItems.firstIndex(where: {
                $0.id == request.anchorId
            }) else {
                return FetchRelayCatsResponseDTO(
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
                    id: media.id,
                    memo: "오늘도 냥냥한 하루!",
                    thumbnailURL: media.thumbnailURL,
                    name: "나비",
                    mediaType: media.mediaType,
                    mediaURL: media.mediaURL,
                    isLiked: false
                )
            }

            return FetchRelayCatsResponseDTO(
                items: Array(items),
                anchorIndex: anchorIndex - lowerBound,
                previousCursor: lowerBound > 0 ? String(lowerBound) : nil,
                nextCursor: upperBound < testFeedItems.count ? String(upperBound) : nil
            )
        },
        deleteMedia: { id in
            Media(
                id: id,
                thumbnailURL: "https://picsum.photos/200/300",
                mediaType: .photo,
                mediaURL: "https://picsum.photos/200/300"
            )
        },
        fetchFeeds: { _, cursor in
            testFeedPage(cursor: cursor)
        }
    )
}
