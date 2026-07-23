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
    let response = try await MediaClient.test.fetchUploadURL("42")

    #expect(response.uploadURL == "https://example.com/uploads/42")
    #expect(response.fileName == "nyangjup-media-42.jpg")
}

@Test
func testClientUploadAndUpdateComplete() async throws {
    let request = UploadMediaRequestDTO(
        catId: "1",
        mediaType: MediaType.photo.rawValue,
        place: "구로구"
    )

    try await MediaClient.test.uploadMedia(request)
    try await MediaClient.test.updateMedia(request)
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
