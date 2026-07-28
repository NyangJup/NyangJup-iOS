import Testing
@testable import DomainMediaInterface
import DomainMediaTesting

@Test
func relayCatStoresDetailFields() {
    let relayCat = RelayCat(
        id: "relay-cat",
        memo: "낮잠 중",
        thumbnailURL: "https://example.com/thumbnail.jpg",
        name: "나비",
        mediaType: .video,
        mediaURL: "https://example.com/video.mp4",
        isLiked: true
    )

    #expect(relayCat.id == "relay-cat")
    #expect(relayCat.memo == "낮잠 중")
    #expect(relayCat.thumbnailURL == "https://example.com/thumbnail.jpg")
    #expect(relayCat.name == "나비")
    #expect(relayCat.mediaType == .video)
    #expect(relayCat.mediaURL == "https://example.com/video.mp4")
    #expect(relayCat.isLiked)
}

@Test
func testClientFetchRelayCatsReturnsAroundPage() async throws {
    let request = FetchRelayCatsRequestDTO(
        anchorId: "feed-photo-3",
        catId: "cat-1",
        beforeCount: 5,
        afterCount: 5
    )

    let response = try await MediaClient.test.fetchRelayCats(request)

    #expect(response.items.contains { $0.mediaType == .photo })
    #expect(response.items.contains { $0.mediaType == .video })
    #expect(response.items[response.anchorIndex].id == request.anchorId)
    #expect(response.items.filter { $0.id == request.anchorId }.count == 1)
    #expect(response.previousCursor == nil)
    #expect(response.nextCursor == "10")
}

@Test
func testClientFetchUploadURLUsesRequestedID() async throws {
    let request = FetchUploadURLRequestDTO(
        catId: "42",
        mediaType: "PHOTO"
    )
    let response = try await MediaClient.test.fetchUploadURL(request)

    #expect(response.uploadURL == "https://example.com/uploads/nyangjup-media-42.jpg")
    #expect(response.fileName == "nyangjup-media-42.jpg")
}

@Test
func testClientFetchUploadURLSupportsVideoWithoutCat() async throws {
    let response = try await MediaClient.test.fetchUploadURL(
        FetchUploadURLRequestDTO(
            catId: nil,
            mediaType: "VIDEO"
        )
    )

    #expect(response.uploadURL == "https://example.com/uploads/nyangjup-media-common.mov")
    #expect(response.fileName == "nyangjup-media-common.mov")
}

@Test
func testClientUploadCompletes() async throws {
    let request = UploadMediaRequestDTO(
        catId: "1",
        fileName: "nyangjup-media-1.jpg",
        mediaType: "PHOTO",
        place: "구로구",
        comment: "귀여워"
    )

    let response = try await MediaClient.test.uploadMedia(request)

    #expect(response.catId == request.catId)
    #expect(response.mediaId == "test-media-id")
    #expect(response.mediaType == request.mediaType)
    #expect(response.mediaURL == "https://example.com/media/\(request.fileName)")
    #expect(response.thumbnailURL == "https://example.com/thumbnails/\(request.fileName).jpg")
    #expect(response.comment == request.comment)
}


@Test
func testClientDeleteMediaReturnsRequestedID() async throws {
    let media = try await MediaClient.test.deleteMedia("8")

    #expect(media.id == "8")
    #expect(media.thumbnailURL == "https://picsum.photos/200/300")
    #expect(media.mediaType == .photo)
    #expect(media.mediaURL == "https://picsum.photos/200/300")
}

@Test
func testClientFetchFeedsReturnsMixedFirstPage() async throws {
    let page = try await MediaClient.test.fetchFeeds("cat-1", nil)

    #expect(page.items.count == 10)
    #expect(page.items.contains { $0.mediaType == .photo })
    #expect(page.items.contains { $0.mediaType == .video })
    #expect(page.nextCursor == "feed-page-2")
}

@Test
func testClientFetchFeedsReturnsLastPageForKnownCursor() async throws {
    let page = try await MediaClient.test.fetchFeeds("cat-1", "feed-page-2")

    #expect(page.items.count == 10)
    #expect(page.items.contains { $0.mediaType == .photo })
    #expect(page.items.contains { $0.mediaType == .video })
    #expect(page.nextCursor == nil)
}

@Test
func testClientFetchFeedsReturnsEmptyPageForUnknownCursor() async throws {
    let page = try await MediaClient.test.fetchFeeds("cat-1", "unknown")

    #expect(page.items.isEmpty)
    #expect(page.nextCursor == nil)
}
