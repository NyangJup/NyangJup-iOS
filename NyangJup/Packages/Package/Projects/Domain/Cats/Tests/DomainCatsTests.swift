import Testing
@testable import DomainCatsInterface
import DomainCatsTesting
@testable import DomainMediaInterface

@Test
func testClientFetchCatsReturnsSampleCats() async throws {
    let cats = try await CatsClient.test.fetchCats(10)

    #expect(cats.count == 4)
    #expect(cats.map(\.id) == [1, 2, 3, 4])
    #expect(cats.map(\.name) == ["꾸꾸", "까까", "냥냥", "야르"])
    #expect(cats.allSatisfy { $0.place == "구로구" })
    #expect(cats.allSatisfy { $0.imageURL == "https://picsum.photos/200/300" })
}

@Test
func testClientFetchCatFeedReturnsSampleFeed() async throws {
    let catFeed = try await CatsClient.test.fetchCatFeed(10)

    #expect(catFeed.id == 1)
    #expect(catFeed.name == "꾸꾸")
    #expect(catFeed.place == "구로구")
    #expect(catFeed.thumbnailURL == "https://picsum.photos/200/300")
    #expect(catFeed.feed.count == 9)
    #expect(catFeed.feed.map(\.id) == Array(1...9))
    #expect(catFeed.feed.prefix(4).allSatisfy { $0.mediaType == .photo })
    #expect(catFeed.feed.dropFirst(4).allSatisfy { $0.mediaType == .video })
}
