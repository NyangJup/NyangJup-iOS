//
//  MediaClientLiveTests.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

import Foundation
import Testing

import CoreNetworkInterface
@testable import DomainMedia
import DomainMediaInterface

@Suite(.serialized)
struct MediaClientLiveTests {
    @Test
    func liveClientBuildsEndpointsAndMapsEntities() async throws {
        let network = RecordingNetworkClient(responses: [
            Data(#"{"uploadURL":"https://upload.example/photo","fileName":"photo.jpg"}"#.utf8),
            Data(#"{"catId":"cat-1","mediaId":"media-1","userId":"user-1","mediaType":"PHOTO","processingStatus":"READY","mediaURL":"https://media.example/photo.jpg","thumbnailURL":"https://media.example/thumb.jpg","comment":"사진"}"#.utf8),
            Data(#"{"catId":"cat-1","mediaId":"media-1","userId":"user-1","mediaType":"VIDEO","processingStatus":"PROCESSING","mediaURL":null,"thumbnailURL":null,"comment":"영상"}"#.utf8),
            Data(#"{"id":"media-1","catId":"cat-1","userId":"user-1","comment":"영상","thumbnailURL":null,"mediaType":"VIDEO","mediaURL":null,"processingStatus":"FAILED"}"#.utf8),
            Data(),
            Data(#"{"items":[{"mediaId":"media-1","catId":"cat-1","userId":"user-1","comment":"영상","place":"서울숲","thumbnailURL":"https://media.example/thumb.jpg","name":"나비","catImageURL":"https://media.example/cat.jpg","mediaType":"VIDEO","mediaURL":"https://media.example/master.m3u8","isLiked":true}],"anchorIndex":0,"previousCursor":"before","nextCursor":"after"}"#.utf8),
            Data(#"{"id":"media-1","catId":"cat-1","userId":"user-1","comment":"영상","thumbnailURL":"https://media.example/thumb.jpg","mediaType":"VIDEO","mediaURL":"https://media.example/master.m3u8","processingStatus":"READY"}"#.utf8)
        ])
        let client = MediaClient.live(
            networkClient: NetworkClient(provider: network)
        )
        let uploadRequest = UploadMediaRequestDTO(
            catId: "cat-1",
            fileName: "photo.jpg",
            mediaType: "PHOTO",
            place: "서울숲",
            comment: "사진"
        )

        let uploadURL = try await client.fetchUploadURL(
            FetchUploadURLRequestDTO(catId: "cat-1", mediaType: "PHOTO")
        )
        let uploaded = try await client.uploadMedia(uploadRequest)
        let updated = try await client.updateMedia("media-1", uploadRequest)
        let fetched = try await client.fetchMedia("media-1")
        try await client.updateIsLiked("media-1", true)
        let relay = try await client.fetchRelayCats(
            FetchRelayCatsRequestDTO(
                anchorId: "media-1",
                catId: "cat-1",
                beforeCount: 5,
                afterCount: 7
            )
        )
        let deleted = try await client.deleteMedia("media-1")

        #expect(uploadURL.fileName == "photo.jpg")
        #expect(uploaded.processingStatus == .ready)
        #expect(updated.processingStatus == .processing)
        #expect(updated.mediaURL == nil)
        #expect(fetched.processingStatus == .failed)
        #expect(relay.items.first?.place == "서울숲")
        #expect(relay.items.first?.mediaURL == "https://media.example/master.m3u8")
        #expect(relay.previousCursor == "before")
        #expect(relay.nextCursor == "after")
        #expect(deleted.processingStatus == .ready)
        #expect(network.paths == [
            "/media/upload-urls",
            "/media",
            "/media/media-1",
            "/media/media-1",
            "/media/media-1/like",
            "/media/relay",
            "/media/media-1"
        ])
        #expect(network.methods == ["POST", "POST", "PUT", "GET", "PUT", "GET", "DELETE"])
        #expect(network.authorizationRequirements.allSatisfy { $0 })
        #expect(network.queries[5] == [
            URLQueryItem(name: "anchorId", value: "media-1"),
            URLQueryItem(name: "catId", value: "cat-1"),
            URLQueryItem(name: "beforeCount", value: "5"),
            URLQueryItem(name: "afterCount", value: "7")
        ])

        let likeBody = try #require(network.bodies[4])
        let likeJSON = try #require(
            JSONSerialization.jsonObject(with: likeBody) as? [String: Bool]
        )
        #expect(likeJSON == ["isLiked": true])
    }

    @Test
    func nullableRequestFieldsEncodeAsExplicitNull() throws {
        let uploadURLData = try JSONEncoder().encode(
            FetchUploadURLRequestDTO(catId: nil, mediaType: "PHOTO")
        )
        let uploadURLJSON = try #require(
            JSONSerialization.jsonObject(with: uploadURLData) as? [String: Any]
        )
        #expect(uploadURLJSON["catId"] is NSNull)

        let mediaData = try JSONEncoder().encode(
            UploadMediaRequestDTO(
                catId: nil,
                fileName: "photo.jpg",
                mediaType: "PHOTO",
                place: nil,
                comment: ""
            )
        )
        let mediaJSON = try #require(
            JSONSerialization.jsonObject(with: mediaData) as? [String: Any]
        )
        #expect(mediaJSON["catId"] is NSNull)
        #expect(mediaJSON["place"] is NSNull)
    }

    @Test
    func presignedUploaderUsesExpectedSourceAndContentType() async throws {
        let recorder = URLRequestRecorder()
        URLProtocolStub.recorder = recorder
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let client = MediaClient.live(
            networkClient: NetworkClient(
                provider: RecordingNetworkClient(responses: [])
            ),
            uploadSession: session
        )
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        try Data([4, 5, 6]).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        try await client.uploadToPresignedURL(
            UploadURL(uploadURL: "https://upload.example/photo", fileName: "photo.jpg"),
            .data(Data([1, 2, 3])),
            .photo
        )
        try await client.uploadToPresignedURL(
            UploadURL(uploadURL: "https://upload.example/video", fileName: "video.mp4"),
            .file(fileURL),
            .video
        )

        let requests = recorder.requests
        #expect(requests.map(\.httpMethod) == ["PUT", "PUT"])
        #expect(requests.map { $0.value(forHTTPHeaderField: "Content-Type") } == [
            "image/jpeg",
            "video/mp4"
        ])
        #expect(requests.map(\.url?.absoluteString) == [
            "https://upload.example/photo",
            "https://upload.example/video"
        ])
    }

    final class RecordingNetworkClient: NetworkClientProtocol, @unchecked Sendable {
        private var responses: [Data]
        private(set) var paths: [String] = []
        private(set) var methods: [String] = []
        private(set) var queries: [[URLQueryItem]?] = []
        private(set) var bodies: [Data?] = []
        private(set) var authorizationRequirements: [Bool] = []

        init(responses: [Data]) {
            self.responses = responses
        }

        func request<T: Decodable>(_ endpoint: any Endpoint) async throws -> T {
            paths.append(endpoint.path)
            methods.append(endpoint.method.rawValue)
            queries.append(endpoint.query)
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

    final class URLRequestRecorder: @unchecked Sendable {
        private let lock = NSLock()
        private var storage: [URLRequest] = []

        var requests: [URLRequest] {
            lock.withLock { storage }
        }

        func record(_ request: URLRequest) {
            lock.withLock { storage.append(request) }
        }
    }

    final class URLProtocolStub: URLProtocol, @unchecked Sendable {
        nonisolated(unsafe) static var recorder: URLRequestRecorder?

        override class func canInit(with request: URLRequest) -> Bool { true }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            Self.recorder?.record(request)
            guard let url = request.url,
                  let response = HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                  ) else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data())
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
