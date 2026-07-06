//
//  CatsClient+Test.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

import DomainCatsInterface
import DomainMediaInterface

extension CatsClient {
    public static let test = Self(
        networkClient: nil,
        fetchCats: { id in
            return [
                Cat(
                    id: "1",
                    name: "꾸꾸",
                    place: "구로구",
                    imageURL: "https://picsum.photos/200/300"
                ),
                Cat(
                    id: "2",
                    name: "까까",
                    place: "구로구",
                    imageURL: "https://picsum.photos/200/300"
                ),
                Cat(
                    id: "3",
                    name: "냥냥",
                    place: "구로구",
                    imageURL: "https://picsum.photos/200/300"
                ),
                Cat(
                    id: "4",
                    name: "야르",
                    place: "구로구",
                    imageURL: "https://picsum.photos/200/300"
                )
            ]
        },
        fetchCatFeed: { id in
            CatFeed(
                id: "1",
                name: "꾸꾸",
                place: "구로구",
                thumbnailURL: "https://picsum.photos/200/300",
                feed: [
                    Media(
                        id: "1",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .photo
                    ),
                    Media(
                        id: "2",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .photo
                    ),
                    Media(
                        id: "3",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .photo
                    ),
                    Media(
                        id: "4",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .photo
                    ),
                    Media(
                        id: "5",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .video
                    ),
                    Media(
                        id: "6",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .video
                    ),
                    Media(
                        id: "7",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .video
                    ),
                    Media(
                        id: "8",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .video
                    ),
                    Media(
                        id: "9",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .video
                    )
                ]
            )
        }
    )
}
