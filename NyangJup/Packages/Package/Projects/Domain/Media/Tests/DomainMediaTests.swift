import Testing
@testable import DomainMediaInterface
import DomainMediaTesting

@Test
func relayCatStoresDetailFields() {
    let relayCat = RelayCat(
        mediaId: "relay-cat",
        catId: "cat-1",
        userId: "user-1",
        comment: "낮잠 중",
        place: "서울숲",
        thumbnailURL: "https://example.com/thumbnail.jpg",
        name: "나비",
        catImageURL: "https://example.com/cat.png",
        mediaType: .video,
        mediaURL: "https://example.com/video.mp4",
        isLiked: true
    )

    #expect(relayCat.mediaId == "relay-cat")
    #expect(relayCat.catId == "cat-1")
    #expect(relayCat.userId == "user-1")
    #expect(relayCat.comment == "낮잠 중")
    #expect(relayCat.place == "서울숲")
    #expect(relayCat.thumbnailURL == "https://example.com/thumbnail.jpg")
    #expect(relayCat.name == "나비")
    #expect(relayCat.catImageURL == "https://example.com/cat.png")
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
    #expect(response.items[response.anchorIndex].mediaId == request.anchorId)
    #expect(response.items.filter { $0.mediaId == request.anchorId }.count == 1)
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
    #expect(response.id == "test-media-id")
    #expect(response.mediaType.rawValue == request.mediaType)
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
