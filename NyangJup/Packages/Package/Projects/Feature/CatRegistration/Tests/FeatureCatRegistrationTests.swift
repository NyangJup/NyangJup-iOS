//
//  FeatureCatRegistrationTests.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

import Foundation
import Testing

import DomainCatsInterface
import DomainCatsTesting
import DomainMediaTesting
@testable import FeatureCatRegistration

@MainActor
@Test
func generatedPixelFileNameIsUsedToCreateCat() async {
    let recorder = CatRegistrationTestSupport.RequestRecorder()
    var catsClient = CatsClient.test
    catsClient.fetchPixelCat = { request in
        await recorder.recordPixelRequest(request)
        return PixelCat(
            fileName: "generated/pixel/cat.png",
            imageURL: "https://example.com/generated-cat.png"
        )
    }
    catsClient.createCat = { request in
        await recorder.recordCreateRequest(request)
        return Cat(
            id: "cat-1",
            name: request.name,
            place: request.place,
            imageURL: "https://example.com/generated-cat.png"
        )
    }
    let viewModel = GenerateCatViewModel(
        photoData: Data(),
        catsClient: catsClient,
        mediaClient: .test,
        onComplete: { _ in },
        onError: {}
    )

    viewModel.send(.network(.fetchPixelCat))
    await CatRegistrationTestSupport.waitUntil {
        viewModel.state.pixelCat != nil
    }

    #expect(await recorder.pixelRequest?.fileName == "nyangjup-media-common.jpg")
    #expect(viewModel.state.pixelImageURL?.absoluteString == "https://example.com/generated-cat.png")
    #expect(viewModel.state.isGenerated)

    viewModel.state.name = "나비"
    viewModel.state.place = "집"
    viewModel.send(.network(.createCat))
    await CatRegistrationTestSupport.waitUntil {
        await recorder.createRequest != nil
    }

    #expect(await recorder.createRequest?.name == "나비")
    #expect(await recorder.createRequest?.place == "집")
    #expect(await recorder.createRequest?.fileName == "generated/pixel/cat.png")
}

@MainActor
@Test
func createCatBeforePixelGenerationShowsErrorWithoutRequest() async {
    let recorder = CatRegistrationTestSupport.RequestRecorder()
    var catsClient = CatsClient.test
    catsClient.createCat = { request in
        await recorder.recordCreateRequest(request)
        return Cat(id: "cat-1", name: request.name, place: request.place, imageURL: "")
    }
    let viewModel = GenerateCatViewModel(
        photoData: Data(),
        catsClient: catsClient,
        mediaClient: .test,
        onComplete: { _ in },
        onError: {}
    )

    viewModel.send(.network(.createCat))
    await Task.yield()

    #expect(viewModel.state.isAlertPrsented)
    #expect(viewModel.state.errorMessage == "생성된 고양이 이미지를 확인해주세요.")
    #expect(await recorder.createRequest == nil)
}

@MainActor
@Test
func pixelGenerationFailureEndsWithAlert() async {
    var catsClient = CatsClient.test
    catsClient.fetchPixelCat = { _ in
        throw CatRegistrationTestSupport.TestError.pixelGenerationFailed
    }
    let viewModel = GenerateCatViewModel(
        photoData: Data(),
        catsClient: catsClient,
        mediaClient: .test,
        onComplete: { _ in },
        onError: {}
    )

    viewModel.send(.network(.fetchPixelCat))
    await CatRegistrationTestSupport.waitUntil {
        viewModel.state.isAlertPrsented
    }

    #expect(viewModel.state.pixelCat == nil)
    #expect(viewModel.state.errorMessage == "이미지 생성에 실패했어요.")
}

private enum CatRegistrationTestSupport {
    enum TestError: Error {
        case pixelGenerationFailed
    }

    actor RequestRecorder {
        private(set) var pixelRequest: PixelCatRequestDTO?
        private(set) var createRequest: CreateCatRequestDTO?

        func recordPixelRequest(_ request: PixelCatRequestDTO) {
            pixelRequest = request
        }

        func recordCreateRequest(_ request: CreateCatRequestDTO) {
            createRequest = request
        }
    }

    @MainActor
    static func waitUntil(
        _ condition: @escaping @MainActor () async -> Bool
    ) async {
        for _ in 0..<100 {
            if await condition() { return }
            await Task.yield()
        }
    }
}
