//
//  DomainCatsTests.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import Foundation
import Testing

import CoreNetworkInterface
@testable import DomainCats
import DomainCatsInterface
import DomainDeviceSecurityInterface

@Test
func catsClientBuildsEndpointsAndMapsEntities() async throws {
    let network = CatsClientTestSupport.RecordingNetworkClient(responses: [
        Data(#"[{"id":"cat-1","name":"나비","place":null,"imageURL":"https://example.com/cat-1.png"}]"#.utf8),
        Data(#"{"id":"cat-2","name":"치즈","place":"공원","imageURL":"https://example.com/cat-2.png"}"#.utf8),
        Data(#"{"id":"cat-2","name":"치즈냥","place":"집","imageURL":"https://example.com/cat-2.png"}"#.utf8),
        Data(#"{"catId":"cat-2","name":"치즈냥","place":"집","thumbnailURL":"https://example.com/cat-2.png","feed":[{"mediaId":"media-1","catId":"cat-2","userId":"user-1","comment":"낮잠","thumbnailURL":"https://example.com/thumb.jpg","mediaType":"VIDEO","mediaURL":"https://example.com/video.mp4"}],"nextCursor":null}"#.utf8),
        Data(),
        Data(#"{"fileName":"generated/pixel/cat.png","imageURL":"https://example.com/pixel.png"}"#.utf8)
    ])
    let security = CatsClientTestSupport.RecordingSecurityClient()
    let client = CatsClient.live(
        networkClient: NetworkClient(provider: network),
        deviceSecurityClient: security.client
    )

    let cats = try await client.fetchCats()
    let created = try await client.createCat(
        CreateCatRequestDTO(name: "치즈", place: "공원", fileName: "source.jpg")
    )
    let updated = try await client.updateCatProfile(
        "cat-2",
        UpdateCatProfileRequestDTO(name: "치즈냥", place: "집")
    )
    let feed = try await client.fetchCatFeed("cat-2", "cursor-1")
    try await client.deleteCat("cat-2")
    let pixelCat = try await client.fetchPixelCat(
        PixelCatRequestDTO(fileName: "source.jpg")
    )

    #expect(cats == [
        Cat(
            id: "cat-1",
            name: "나비",
            place: nil,
            imageURL: "https://example.com/cat-1.png"
        )
    ])
    #expect(created.name == "치즈")
    #expect(updated.name == "치즈냥")
    #expect(feed.cat.id == "cat-2")
    #expect(feed.cat.imageURL == "https://example.com/cat-2.png")
    #expect(feed.items.map(\.id) == ["media-1"])
    #expect(feed.items.map(\.catId) == ["cat-2"])
    #expect(feed.items.first?.mediaType == .video)
    #expect(feed.nextCursor == nil)
    #expect(pixelCat == PixelCat(
        fileName: "generated/pixel/cat.png",
        imageURL: "https://example.com/pixel.png"
    ))

    #expect(network.paths == [
        "/cats",
        "/cats",
        "/cats/cat-2",
        "/cats/cat-2/feed",
        "/cats/cat-2",
        "/cats/pixel"
    ])
    #expect(network.methods == ["GET", "POST", "PATCH", "GET", "DELETE", "POST"])
    #expect(network.authorizationRequirements.allSatisfy { $0 })
    #expect(network.queries[3] == [URLQueryItem(name: "cursor", value: "cursor-1")])
    #expect(network.headers[5] == CatsClientTestSupport.assertionHeaders)
    #expect(security.purposes == [.pixelGeneration])
    #expect(security.paths == ["/cats/pixel"])

    let createBody = try #require(network.bodies[1])
    let createJSON = try #require(
        JSONSerialization.jsonObject(with: createBody) as? [String: String]
    )
    #expect(createJSON == [
        "name": "치즈",
        "place": "공원",
        "fileName": "source.jpg"
    ])

    let pixelBody = try #require(network.bodies[5])
    let pixelJSON = try #require(
        JSONSerialization.jsonObject(with: pixelBody) as? [String: String]
    )
    #expect(pixelJSON == ["fileName": "source.jpg"])
}

@Test
func catFeedRejectsUnsupportedMediaType() async throws {
    let network = CatsClientTestSupport.RecordingNetworkClient(responses: [
        Data(#"{"catId":"cat-1","name":"나비","place":null,"thumbnailURL":"https://example.com/cat.png","feed":[{"mediaId":"media-1","catId":"cat-1","userId":"user-1","comment":"","thumbnailURL":"https://example.com/thumb","mediaType":"AUDIO","mediaURL":"https://example.com/media"}],"nextCursor":"cursor-2"}"#.utf8)
    ])
    let security = CatsClientTestSupport.RecordingSecurityClient()
    let client = CatsClient.live(
        networkClient: NetworkClient(provider: network),
        deviceSecurityClient: security.client
    )

    await #expect(throws: NetworkError.decoding) {
        try await client.fetchCatFeed("cat-1", nil)
    }
    #expect(network.queries == [nil])
}

private enum CatsClientTestSupport {
    static let assertion = AppAttestAssertion(
        keyId: "key-id",
        challengeId: "challenge-id",
        assertion: "assertion"
    )
    static let assertionHeaders = [
        "X-App-Attest-Key-Id": "key-id",
        "X-App-Attest-Challenge-Id": "challenge-id",
        "X-App-Attest-Assertion": "assertion"
    ]

    final class RecordingNetworkClient: NetworkClientProtocol, @unchecked Sendable {
        private var responses: [Data]
        private(set) var paths: [String] = []
        private(set) var methods: [String] = []
        private(set) var queries: [[URLQueryItem]?] = []
        private(set) var bodies: [Data?] = []
        private(set) var headers: [[String: String]?] = []
        private(set) var authorizationRequirements: [Bool] = []

        init(responses: [Data]) {
            self.responses = responses
        }

        func request<T: Decodable>(_ endpoint: any Endpoint) async throws -> T {
            paths.append(endpoint.path)
            methods.append(endpoint.method.rawValue)
            queries.append(endpoint.query)
            headers.append(endpoint.headers)
            authorizationRequirements.append(endpoint.requiresAuthorization)
            if let body = endpoint.body {
                bodies.append(try JSONEncoder().encode(body))
            } else {
                bodies.append(nil)
            }

            let data = responses.removeFirst()
            if data.isEmpty, let response = EmptyResponse() as? T {
                return response
            }
            return try JSONDecoder().decode(T.self, from: data)
        }
    }

    final class RecordingSecurityClient: @unchecked Sendable {
        private(set) var purposes: [AppAttestPurpose] = []
        private(set) var paths: [String] = []

        var client: DeviceSecurityClient {
            DeviceSecurityClient(
                authenticate: {},
                generateAssertion: { [weak self] purpose, endpoint in
                    self?.purposes.append(purpose)
                    self?.paths.append(endpoint.path)
                    return CatsClientTestSupport.assertion
                }
            )
        }
    }
}
