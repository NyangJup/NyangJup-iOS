import Foundation
import SwiftUI
import Testing
import UIKit

@testable import CoreImageLoader
import CoreImageLoaderInterface

@Suite(.serialized)
struct CoreImageLoaderTests {
    private let targetSize = CGSize(width: 20, height: 20)

    @Test
    func invalidImageDimensionsThrowBeforeLoading() async throws {
        let network = NetworkStub()
        let loader = try makeLoader(network: network)
        let invalidInputs: [(targetSize: CGSize, scale: CGFloat)] = [
            (.zero, 1),
            (CGSize(width: 100, height: 0), 1),
            (CGSize(width: -1, height: 100), 1),
            (CGSize(width: CGFloat.infinity, height: 100), 1),
            (CGSize(width: CGFloat.nan, height: 100), 1),
            (CGSize(width: 100, height: 100), 0),
            (CGSize(width: 100, height: 100), -1),
            (CGSize(width: 100, height: 100), CGFloat.infinity),
            (CGSize(width: 100, height: 100), CGFloat.nan)
        ]

        for input in invalidInputs {
            do {
                _ = try await loader.image(
                    for: uniqueURL(),
                    targetSize: input.targetSize,
                    scale: input.scale
                )

                Issue.record("Expected invalidTargetSize for \(input)")
            } catch ImageDecodingError.invalidTargetSize {
                continue
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }

        #expect(network.requestCount == 0)
    }

    @Test
    func emptyAllowedSourcesThrowsCacheMissWithoutLoading() async throws {
        let network = NetworkStub()
        let loader = try makeLoader(network: network)

        await #expect(throws: NZImageLoaderError.self) {
            _ = try await loader.image(
                for: uniqueURL(),
                targetSize: targetSize,
                scale: 2,
                allowedSources: []
            )
        }

        #expect(network.requestCount == 0)
    }

    @Test
    func memorySourceReusesDecodedImage() async throws {
        let network = NetworkStub(response: .success(imageData))
        let loader = try makeLoader(network: network)
        let url = uniqueURL()

        _ = try await loader.image(
            for: url,
            targetSize: targetSize,
            scale: 2,
            allowedSources: [.memory, .network]
        )
        _ = try await loader.image(
            for: url,
            targetSize: targetSize,
            scale: 2,
            allowedSources: [.memory, .network]
        )

        #expect(network.requestCount == 1)
    }

    @Test
    func networkOnlyDoesNotPopulateMemoryOrDiskCache() async throws {
        let network = NetworkStub(response: .success(imageData))
        let diskCache = try DiskImageCache(maxSize: 1_024 * 1_024)
        let loader = makeLoader(network: network, diskCache: diskCache)
        let url = uniqueURL()

        _ = try await loader.image(
            for: url,
            targetSize: targetSize,
            scale: 2,
            allowedSources: [.network]
        )
        _ = try await loader.image(
            for: url,
            targetSize: targetSize,
            scale: 2,
            allowedSources: [.memory, .disk, .network]
        )

        #expect(network.requestCount == 2)
    }

    @Test
    func diskSourceReusesDownloadedDataAcrossLoaders() async throws {
        let network = NetworkStub(response: .success(imageData))
        let diskCache = try DiskImageCache(maxSize: 1_024 * 1_024)
        let url = uniqueURL()

        _ = try await makeLoader(network: network, diskCache: diskCache).image(
            for: url,
            targetSize: targetSize,
            scale: 2,
            allowedSources: [.disk, .network]
        )
        _ = try await makeLoader(network: network, diskCache: diskCache).image(
            for: url,
            targetSize: targetSize,
            scale: 2,
            allowedSources: [.disk]
        )

        #expect(network.requestCount == 1)
    }

    @Test(arguments: [199, 300, 404, 500])
    func nonSuccessHTTPResponseIsRejected(statusCode: Int) async throws {
        let network = NetworkStub(
            response: .failure(statusCode: statusCode, data: imageData)
        )
        let loader = try makeLoader(network: network)

        await #expect(throws: NZImageLoaderError.self) {
            _ = try await loader.image(
                for: uniqueURL(),
                targetSize: targetSize,
                scale: 2,
                allowedSources: [.network]
            )
        }
    }

    @Test
    func emptyNetworkDataIsRejected() async throws {
        let network = NetworkStub(response: .success(Data()))
        let loader = try makeLoader(network: network)

        await #expect(throws: NZImageLoaderError.self) {
            _ = try await loader.image(
                for: uniqueURL(),
                targetSize: targetSize,
                scale: 2,
                allowedSources: [.network]
            )
        }
    }

    @Test
    func concurrentRequestsForSameURLShareNetworkRequest() async throws {
        let gate = DispatchSemaphore(value: 0)
        let network = NetworkStub(response: .gated(imageData, gate: gate))
        let loader = try makeLoader(network: network)
        let url = uniqueURL()

        async let first = loader.image(
            for: url,
            targetSize: targetSize,
            scale: 2,
            allowedSources: [.network]
        )
        async let second = loader.image(
            for: url,
            targetSize: targetSize,
            scale: 2,
            allowedSources: [.network]
        )

        try await waitUntil { network.requestCount == 1 }
        gate.signal()
        _ = try await (first, second)

        #expect(network.requestCount == 1)
    }

    @Test @MainActor
    func asyncImagePlaceholderCanBeOmitted() {
        let view = NZAsyncImage(
            url: uniqueURL(),
            targetSize: targetSize
        ) { image in
            image
        }

        _ = view
    }

    @Test @MainActor
    func asyncImageUsesEnvironmentClientScaleAndOptions() async throws {
        let recorder = ImageLoadRecorder()
        let url = uniqueURL()
        let options: ImageLoaderClient.CacheOptions = [.disk, .network]
        let client = ImageLoaderClient { loadedURL, size, scale, loadedOptions in
            recorder.record(
                url: loadedURL,
                targetSize: size,
                scale: scale,
                options: loadedOptions
            )
            return UIImage(data: imageData)!
        }
        let view = NZAsyncImage(
            url: url,
            targetSize: targetSize,
            options: options
        ) { image in
            image
        }
        .environment(\.displayScale, 3)
        .environment(\.imageLoaderClient, client)
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)

        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()

        try await waitUntil { recorder.arguments != nil }

        let arguments = try #require(recorder.arguments)
        #expect(arguments.url == url)
        #expect(arguments.targetSize == targetSize)
        #expect(arguments.scale == 3)
        #expect(arguments.options == options)

        window.isHidden = true
    }

    @Test @MainActor
    func environmentClientDefaultsToUnconfiguredError() async {
        let client = EnvironmentValues().imageLoaderClient

        await #expect(throws: NZImageLoaderError.self) {
            _ = try await client.loadImage(
                uniqueURL(),
                targetSize,
                2,
                [.network]
            )
        }
    }

    private func makeLoader(network: NetworkStub) throws -> ImageLoader {
        try makeLoader(
            network: network,
            diskCache: DiskImageCache(maxSize: 1_024 * 1_024)
        )
    }

    private func makeLoader(
        network: NetworkStub,
        diskCache: DiskImageCache
    ) -> ImageLoader {
        let configuration = URLSessionConfiguration.ephemeral
        StubURLProtocol.install(network)
        configuration.protocolClasses = [StubURLProtocol.self]

        return ImageLoader(
            session: URLSession(configuration: configuration),
            diskCache: diskCache
        )
    }
}

private let imageData = Data(
    base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
)!

private func uniqueURL() -> URL {
    URL(string: "https://example.com/\(UUID().uuidString).png")!
}

private func waitUntil(
    timeout: Duration = .seconds(1),
    condition: @escaping @Sendable () -> Bool
) async throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)

    while !condition() {
        guard clock.now < deadline else {
            Issue.record("Timed out waiting for condition")
            return
        }

        await Task.yield()
    }
}

private final class ImageLoadRecorder: @unchecked Sendable {
    struct Arguments: Sendable {
        let url: URL
        let targetSize: CGSize
        let scale: CGFloat
        let options: ImageLoaderClient.CacheOptions
    }

    private let lock = NSLock()
    private var storedArguments: Arguments?

    var arguments: Arguments? {
        lock.withLock { storedArguments }
    }

    func record(
        url: URL,
        targetSize: CGSize,
        scale: CGFloat,
        options: ImageLoaderClient.CacheOptions
    ) {
        lock.withLock {
            storedArguments = Arguments(
                url: url,
                targetSize: targetSize,
                scale: scale,
                options: options
            )
        }
    }
}

private final class NetworkStub: @unchecked Sendable {
    enum Response: @unchecked Sendable {
        case success(Data)
        case failure(statusCode: Int, data: Data)
        case gated(Data, gate: DispatchSemaphore)
    }

    private let lock = NSLock()
    private var storedRequestCount = 0
    private let response: Response

    init(response: Response = .success(imageData)) {
        self.response = response
    }

    var requestCount: Int {
        lock.withLock { storedRequestCount }
    }

    fileprivate func respond(to protocol: URLProtocol) {
        lock.withLock { storedRequestCount += 1 }

        let statusCode: Int
        let data: Data

        switch response {
        case let .success(responseData):
            statusCode = 200
            data = responseData
        case let .failure(responseStatusCode, responseData):
            statusCode = responseStatusCode
            data = responseData
        case let .gated(responseData, gate):
            gate.wait()
            statusCode = 200
            data = responseData
        }

        let response = HTTPURLResponse(
            url: `protocol`.request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        `protocol`.client?.urlProtocol(
            `protocol`,
            didReceive: response,
            cacheStoragePolicy: .notAllowed
        )
        `protocol`.client?.urlProtocol(`protocol`, didLoad: data)
        `protocol`.client?.urlProtocolDidFinishLoading(`protocol`)
    }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var storedStub: NetworkStub?

    static func install(_ stub: NetworkStub) {
        lock.withLock { storedStub = stub }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let stub = Self.lock.withLock { Self.storedStub }
        stub?.respond(to: self)
    }

    override func stopLoading() {}
}
