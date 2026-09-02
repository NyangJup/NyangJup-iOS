import Foundation
import UIKit.UIImage
import Vision

import DomainCatsInterface
import DomainMediaInterface
import FeatureCommonInterface

@MainActor
@Observable
final class GenerateCatViewModel: NZViewModel {
    struct State {
        var name = ""
        var place = ""

        var isCreating: Bool?

        var isGenerated = false

        var isLoading = false
        var errorMessage: String?
        var photoData: Data
        var pixelCat: PixelCat?
        var isAlertPrsented: Bool = false

        var pixelImageURL: URL? {
            pixelCat.flatMap { URL(string: $0.imageURL) }
        }

        init(photoData: Data) {
            self.photoData = photoData
        }
    }

    enum Action {
        case view(View)
        case network(Network)

        enum View {
            case onAppear
            case submitButtonTapped
            case errorDismissed
            case alertConfirmTapped
            case showGeneratedImageButtonTapped
        }

        enum Network {
            case fetchPixelCat
            case createCat
        }
    }

    var state: State

    private let catsClient: CatsClient
    private let mediaClient: MediaClient
    private let onComplete: @MainActor (Cat) -> Void
    private let onError: @MainActor () -> Void

    init(
        photoData: Data,
        catsClient: CatsClient,
        mediaClient: MediaClient,
        onComplete: @escaping @MainActor (Cat) -> Void,
        onError: @escaping @MainActor () -> Void
    ) {
        self.state = State(photoData: photoData)
        self.catsClient = catsClient
        self.mediaClient = mediaClient
        self.onComplete = onComplete
        self.onError = onError
    }

    func send(_ action: Action) {
        switch action {
        case let .view(action):
            handleViewAction(action)

        case let .network(action):
            handleNetworkAction(action)
        }
    }
}

// MARK: - Action

private extension GenerateCatViewModel {
    func handleViewAction(_ action: Action.View) {
        switch action {
        case .onAppear:
            let isCat = classifyIsCatImage(data: state.photoData)

            if isCat {
                send(.network(.fetchPixelCat))
            } else {
                state.errorMessage = """
                이미지에 고양이가 보이지 않아요
                사진을 다시 업로드해주세요!
                """
                state.isAlertPrsented = true
            }

        case .submitButtonTapped:
            send(.network(.createCat))

        case .errorDismissed:
            state.errorMessage = nil

        case .alertConfirmTapped:
            state.errorMessage = nil
            onError()

        case .showGeneratedImageButtonTapped:
            state.isCreating = false
        }
    }

    func handleNetworkAction(_ action: Action.Network) {
        switch action {
        case .fetchPixelCat:
            state.isCreating = true
            state.isGenerated = false

            Task {
                do {
                    let urlResponse = try await mediaClient.fetchUploadURL(
                        .init(
                            catId: nil,
                            mediaType: "PHOTO"
                        )
                    )

                    try await mediaClient.uploadToPresignedURL(
                        urlResponse,
                        .data(state.photoData),
                        .photo
                    )

                    let pixelCat = try await catsClient.fetchPixelCat(
                        PixelCatRequestDTO(fileName: urlResponse.fileName)
                    )

                    state.pixelCat = pixelCat

                    state.isGenerated = true

                } catch {
                    state.isAlertPrsented = true
                    state.errorMessage = "이미지 생성에 실패했어요."
                }
            }

        case .createCat:
            guard let pixelCat = state.pixelCat else {
                state.isAlertPrsented = true
                state.errorMessage = "생성된 고양이 이미지를 확인해주세요."
                return
            }

            state.isLoading = true

            Task {
                defer {
                    state.isLoading = false
                }

                do {
                    let cat = try await catsClient.createCat(
                        CreateCatRequestDTO(
                            name: state.name,
                            place: state.place,
                            fileName: pixelCat.fileName
                        )
                    )

                    onComplete(cat)

                } catch {
                    state.isAlertPrsented = true
                    state.errorMessage = "픽셀 고양이 생성에 실패했어요."
                }
            }
        }
    }

    func classifyIsCatImage(data: Data) -> Bool {
        guard let cgImage = UIImage(data: data)?.cgImage else {
            return false
        }

        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            options: [:]
        )

        do {
            try handler.perform([request])

            guard let observations = request.results else {
                return false
            }

            return observations
                .prefix(3)
                .contains {
                    $0.identifier
                        .lowercased()
                        .contains("cat")
                }

        } catch {
            return false
        }
    }
}
