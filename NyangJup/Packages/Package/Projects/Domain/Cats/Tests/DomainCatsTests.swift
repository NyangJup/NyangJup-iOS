//
//  DomainCatsTests.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import Testing
@testable import DomainCatsInterface
import DomainCatsTesting
@testable import DomainMediaInterface

@Test
func testClientFetchCatsReturnsSampleCats() async throws {
    let cats = try await CatsClient.test.fetchCats("10")

    #expect(cats.count == 3)
    #expect(cats.map(\.id) == ["1", "2", "3"])
    #expect(cats.map(\.name) == ["꾸꾸", "까까", "냥냥"])
    #expect(cats.allSatisfy { $0.place == "구로구" })
    #expect(cats.map(\.imageURL) == [
        "https://picsum.photos/seed/nayngjup-cat-1/200/200",
        "https://picsum.photos/seed/nayngjup-cat-2/200/200",
        "https://picsum.photos/seed/nayngjup-cat-3/200/200"
    ])
}

@Test
func testClientCreateCatUsesRequestValues() async throws {
    let request = CreateCatRequestDTO(
        name: "나비",
        place: "집",
        fileName: "https://example.com/cats/created.png"
    )

    let cat = try await CatsClient.test.createCat(request)

    #expect(cat.id == "created-cat")
    #expect(cat.name == request.name)
    #expect(cat.place == request.place)
    #expect(cat.imageURL == request.fileName)
}

@Test
func testClientFetchCatFeedReturnsSampleFeed() async throws {
    let catFeed = try await CatsClient.test.fetchCatFeed("10")

    #expect(catFeed.id == "1")
    #expect(catFeed.name == "꾸꾸")
    #expect(catFeed.place == "구로구")
    #expect(catFeed.thumbnailURL == "https://picsum.photos/200/300")
    #expect(catFeed.feed.count == 9)
    #expect(catFeed.feed.map(\.id) == ["1", "2", "3", "4", "5", "6", "7", "8", "9"])
    #expect(catFeed.feed.prefix(4).allSatisfy { $0.mediaType == .photo })
    #expect(catFeed.feed.dropFirst(4).allSatisfy { $0.mediaType == .video })
}
