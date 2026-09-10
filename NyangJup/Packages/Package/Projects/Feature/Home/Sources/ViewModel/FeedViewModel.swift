//
//  FeedViewModel.swift
//  NJPackage
//
//  Created by 정지훈 on 7/16/26.
//

import Foundation

import DomainMediaInterface
import DomainCatsInterface
import CoreVideoInterface
import FeatureCaptureInterface
import FeatureCommonInterface
import FeatureHomeInterface
import FeatureRelayCatInterface

@MainActor
@Observable
public final class FeedViewModel: NZViewModel {
    nonisolated static let nameMaxLength = 5
    nonisolated static let placeMaxLength = 20

    public struct State {
        var cat: Cat
        var items: [FeedItem] = []
        var nextCursor: String?
        var hasLoadedInitialFeed: Bool = false
        var isLoading: Bool = false
        var isCameraPresented: Bool = false
        var showsEditAlert: Bool = false
        var showsDeleteAlert: Bool = false
        var showsUploadFailureAlert: Bool = false
        var editName: String = ""
        var editPlace: String = ""

        var canUpdateProfile: Bool {
            !editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !editPlace.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && editName.count <= FeedViewModel.nameMaxLength
                && editPlace.count <= FeedViewModel.placeMaxLength
        }

        public init(
            cat: Cat
        ) {
            self.cat = cat
        }
    }

    public enum Action {
        case view(View)
        case network(Network)
        case `internal`(Internal)

        public enum View {
            case onAppear
            case loadNextPage
            case feedContentTapped(Media)
            case plusButtonTapped
            case cameraCompleted(Media)
            case videoUploadRequested(VideoUploadRequest)
            case cameraDismissed
            case editButtonTapped
            case updateProfileAlertTapped
            case deleteButtonTapped
            case deleteAlertTapped
        }

        public enum Network {
            case fetchFeed(cursor: String?)
        }

        public enum Internal {
            case relayCatLikeUpdated(mediaId: String, isLiked: Bool)
            case relayCatMediaUpdated(Media)
            case relayCatMediaDeleted(mediaId: String)
            case videoUploadCompleted(id: UUID, media: Media)
            case videoUploadFailed(id: UUID)
        }
    }

    public var state: State
    weak var coordinator: (any Coordinator<HomeRoute>)?
    let catsClient: CatsClient
    let mediaClient: MediaClient
    let videoTrimClient: VideoTrimClient
    private let onCatDeleted: @MainActor @Sendable (String) -> Void
    private let onCatUpdated: @MainActor @Sendable (Cat) -> Void

    public init(
        cat: Cat,
        catsClient: CatsClient,
        mediaClient: MediaClient,
        videoTrimClient: VideoTrimClient,
        onCatDeleted: @escaping @MainActor @Sendable (String) -> Void,
        onCatUpdated: @escaping @MainActor @Sendable (Cat) -> Void,
        coordinator: (any Coordinator<HomeRoute>)? = nil
    ) {
        self.state = State(cat: cat)
        self.catsClient = catsClient
        self.mediaClient = mediaClient
        self.videoTrimClient = videoTrimClient
        self.onCatDeleted = onCatDeleted
        self.onCatUpdated = onCatUpdated
        self.coordinator = coordinator
    }

    public func send(_ action: Action) {
        switch action {
        case let .view(viewAction):
            handleViewAction(viewAction)

        case let .internal(internalAction):
            handleInternalAction(internalAction)

        case let .network(networkAction):
            handleNetworkAction(networkAction)
        }
    }

    private func handleViewAction(_ action: Action.View) {
        switch action {
        case .onAppear:
            guard state.items.isEmpty, !state.hasLoadedInitialFeed else { return }
            send(.network(.fetchFeed(cursor: nil)))

        case .loadNextPage:
            guard let nextCursor = state.nextCursor else { return }
            send(.network(.fetchFeed(cursor: nextCursor)))

        case let .feedContentTapped(media):
            guard let catId = media.catId else {
                return
            }
            let route = HomeRoute.relayCat(
                RelayCat(
                    mediaId: media.id,
                    catId: catId,
                    userId: media.userId,
                    comment: media.comment,
                    place: state.cat.place,
                    thumbnailURL: media.thumbnailURL,
                    name: state.cat.name,
                    catImageURL: state.cat.imageURL,
                    mediaType: media.mediaType,
                    mediaURL: media.mediaURL,
                    isLiked: media.isLiked
                )
            )

            if let coordinator = coordinator as? HomeCoordinator {
                coordinator.push(to: route, relayCatDelegate: makeRelayCatDelegate())
            } else {
                coordinator?.push(to: route)
            }
            
        case .plusButtonTapped:
            state.isCameraPresented = true

        case let .cameraCompleted(media):
            state.isCameraPresented = false
            state.items.insert(.media(media), at: 0)

        case let .videoUploadRequested(request):
            let uploadID = UUID()
            let mediaClient = mediaClient
            let videoTrimClient = videoTrimClient
            state.isCameraPresented = false
            state.items.insert(.uploading(uploadID), at: 0)

            Task { [weak self] in
                do {
                    let media = try await Self.uploadVideo(
                        request,
                        mediaClient: mediaClient,
                        videoTrimClient: videoTrimClient
                    )
                    self?.send(.internal(.videoUploadCompleted(
                        id: uploadID,
                        media: media
                    )))
                } catch {
                    self?.send(.internal(.videoUploadFailed(id: uploadID)))
                }
            }

        case .cameraDismissed:
            state.isCameraPresented = false

        case .editButtonTapped:
            state.editName = state.cat.name
            state.editPlace = state.cat.place ?? ""
            state.showsEditAlert = true

        case .updateProfileAlertTapped:
            let name = state.editName.trimmingCharacters(in: .whitespacesAndNewlines)
            let place = state.editPlace.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty,
                  !place.isEmpty,
                  name.count <= Self.nameMaxLength,
                  place.count <= Self.placeMaxLength else {
                return
            }

            Task {
                do {
                    let updatedCat = try await catsClient.updateCatProfile(
                        state.cat.id,
                        UpdateCatProfileRequestDTO(
                            name: name,
                            place: place
                        )
                    )
                    state.cat = updatedCat
                    onCatUpdated(updatedCat)
                } catch {

                }
            }

        case .deleteButtonTapped:
            state.showsDeleteAlert = true

        case .deleteAlertTapped:
            Task {
                do {
                    let catId = state.cat.id
                    try await catsClient.deleteCat(catId)
                    onCatDeleted(catId)
                    coordinator?.pop()
                } catch {

                }
            }
        }
    }

    private func handleInternalAction(_ action: Action.Internal) {
        switch action {
        case let .relayCatLikeUpdated(mediaId, isLiked):
            guard let index = state.items.firstIndex(where: { $0.media?.id == mediaId }),
                  let media = state.items[index].media else {
                return
            }
            state.items[index] = .media(copyMedia(from: media, isLiked: isLiked))

        case let .relayCatMediaUpdated(updatedMedia):
            guard let index = state.items.firstIndex(where: { $0.media?.id == updatedMedia.id }),
                  let media = state.items[index].media else {
                return
            }
            state.items[index] = .media(copyMedia(
                from: updatedMedia,
                isLiked: media.isLiked
            ))

        case let .relayCatMediaDeleted(mediaId):
            state.items.removeAll { $0.media?.id == mediaId }

        case let .videoUploadCompleted(id, media):
            guard let index = state.items.firstIndex(where: { $0.uploadID == id }) else {
                return
            }
            state.items[index] = .media(media)

        case let .videoUploadFailed(id):
            guard state.items.contains(where: { $0.uploadID == id }) else {
                return
            }
            state.items.removeAll { $0.uploadID == id }
            state.showsUploadFailureAlert = true
        }
    }

    func makeRelayCatDelegate() -> RelayCatDelegate {
        RelayCatDelegate { [weak self] action in
            guard let self else { return }

            switch action {
            case let .likeUpdated(mediaId, isLiked):
                self.send(.internal(.relayCatLikeUpdated(
                    mediaId: mediaId,
                    isLiked: isLiked
                )))
            case let .mediaUpdated(media):
                self.send(.internal(.relayCatMediaUpdated(media)))
            case let .mediaDeleted(mediaId):
                self.send(.internal(.relayCatMediaDeleted(mediaId: mediaId)))
            }
        }
    }

    private func copyMedia(from media: Media, isLiked: Bool) -> Media {
        Media(
            id: media.id,
            catId: media.catId,
            userId: media.userId,
            comment: media.comment,
            thumbnailURL: media.thumbnailURL,
            mediaType: media.mediaType,
            mediaURL: media.mediaURL,
            isLiked: isLiked
        )
    }

    private static func uploadVideo(
        _ request: VideoUploadRequest,
        mediaClient: MediaClient,
        videoTrimClient: VideoTrimClient
    ) async throws -> Media {
        var outputURL: URL?
        defer {
            if let outputURL {
                try? FileManager.default.removeItem(at: outputURL)
            }
        }

        let trimmedURL = try await videoTrimClient.exportTrimmedVideo(
            sourceURL: request.sourceURL,
            startTime: request.trimStartTime,
            endTime: request.trimEndTime
        )
        outputURL = trimmedURL
        let thumbnailData = try await videoTrimClient.generateUploadThumbnail(
            from: request.sourceURL,
            at: request.trimStartTime
        )
        return try await mediaClient.uploadVideo(
            PreparedVideoUpload(
                videoURL: trimmedURL,
                thumbnailData: thumbnailData,
                catID: request.catID,
                place: request.place,
                comment: request.comment
            )
        )
    }

    private func handleNetworkAction(_ action: Action.Network) {
        switch action {
        case let .fetchFeed(cursor):
            guard !state.isLoading else { return }
            state.isLoading = true

            Task {
                defer { state.isLoading = false }

                do {
                    let page = try await catsClient.fetchCatFeed(
                        state.cat.id,
                        cursor
                    )

                    state.cat = page.cat
                    onCatUpdated(page.cat)

                    if cursor == nil {
                        let uploadingItems = state.items.filter { $0.uploadID != nil }
                        state.items = uploadingItems + page.items.map(FeedItem.media)
                        state.hasLoadedInitialFeed = true
                    } else {
                        state.items.append(contentsOf: page.items.map(FeedItem.media))
                    }
                    state.nextCursor = page.nextCursor
                } catch {

                }
            }
        }
    }

}
