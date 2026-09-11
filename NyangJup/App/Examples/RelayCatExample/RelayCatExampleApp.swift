//
//  RelayCatExampleApp.swift
//  NyangJup
//
//  Created by 정지훈 on 9/11/26.
//

import SwiftUI

import CoreAdsTesting
import CoreImageLoaderTesting
import DomainMediaInterface
import DomainMediaTesting
import FeatureRelayCat
import FeatureRelayCatInterface

@main
struct RelayCatExampleApp: App {
    private let dependencies = RelayCatExampleDependencies.example()

    var body: some Scene {
        WindowGroup {
            dependencies.factory.makeView(
                RelayCatConfiguration(relayCat: dependencies.anchor),
                RelayCatDelegate { _ in }
            )
            .environment(\.imageLoaderClient, .test)
            .environment(\.nativeAdFactory, .test)
        }
    }
}

@MainActor
private struct RelayCatExampleDependencies {
    let factory: RelayCatFactory
    let anchor: RelayCat

    static func example() -> Self {
        let videoURL = Bundle.main.url(
            forResource: "relay-example",
            withExtension: "mp4"
        )?.absoluteString ?? ""
        let photo = RelayCat(
            mediaId: "relay-photo",
            catId: "example-cat",
            userId: "example-user",
            comment: "로컬 사진 fixture",
            place: "테스트 공원",
            thumbnailURL: "example://relay-photo",
            name: "냥이",
            catImageURL: "example://cat-avatar",
            mediaType: .photo,
            mediaURL: "example://relay-photo",
            isLiked: false
        )
        let video = RelayCat(
            mediaId: "relay-video",
            catId: "example-cat",
            userId: "example-user",
            comment: "로컬 영상 fixture",
            place: "테스트 공원",
            thumbnailURL: "example://relay-video",
            name: "냥이",
            catImageURL: "example://cat-avatar",
            mediaType: .video,
            mediaURL: videoURL,
            isLiked: true
        )
        var mediaClient = MediaClient.test
        mediaClient.fetchRelayCats = { request in
            RelayPage(
                items: [photo, video],
                anchorIndex: request.anchorId == video.mediaId ? 1 : 0,
                previousCursor: nil,
                nextCursor: nil
            )
        }

        return Self(
            factory: .live(
                mediaClient: mediaClient,
                imageLoaderClient: .test,
                adsClient: .test
            ),
            anchor: photo
        )
    }
}
