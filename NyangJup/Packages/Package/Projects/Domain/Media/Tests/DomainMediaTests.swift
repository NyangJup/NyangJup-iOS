import Testing
@testable import DomainMediaInterface
import DomainMediaTesting

@Test
func testClientFetchUploadURLUsesRequestedID() async throws {
    let response = try await MediaClient.test.fetchUploadURL(42)

    #expect(response.uploadURL == "https://example.com/uploads/42")
    #expect(response.fileName == "nyangjup-media-42.jpg")
}

@Test
func testClientUploadAndUpdateComplete() async throws {
    let request = UploadMediaRequestDTO(
        catId: 1,
        mediaType: MediaType.photo.rawValue,
        place: "구로구"
    )

    try await MediaClient.test.uploadMedia(request)
    try await MediaClient.test.updateMedia(request)
}

@Test
func testClientFetchMediaReturnsRequestedID() async throws {
    let media = try await MediaClient.test.fetchMedia(7)

    #expect(media.id == 7)
    #expect(media.thumbnailURL == "https://picsum.photos/200/300")
    #expect(media.mediaType == .photo)
}

@Test
func testClientDeleteMediaReturnsRequestedID() async throws {
    let media = try await MediaClient.test.deleteMedia(8)

    #expect(media.id == 8)
    #expect(media.thumbnailURL == "https://picsum.photos/200/300")
    #expect(media.mediaType == .photo)
}
