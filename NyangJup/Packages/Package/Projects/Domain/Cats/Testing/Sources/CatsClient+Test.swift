//
//  CatsClient+Test.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

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
                    appearanceKey: "abyssinian"
                ),
                Cat(
                    id: "2",
                    name: "까까",
                    place: "구로구",
                    appearanceKey: "americanShorthair"
                ),
                Cat(
                    id: "3",
                    name: "냥냥",
                    place: "구로구",
                    appearanceKey: "bengal"
                ),
                Cat(
                    id: "4",
                    name: "야르",
                    place: "구로구",
                    appearanceKey: "britishShorthair"
                )
            ]
        },
        createCat: { request in
            Cat(
                id: "created-cat",
                name: request.name,
                place: "",
                appearanceKey: request.appearanceKey
            )
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
                        catId: id,
                        userId: "test-user-id",
                        comment: "",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .photo,
                        mediaURL: "https://picsum.photos/200/300"
                    ),
                    Media(
                        id: "2",
                        catId: id,
                        userId: "test-user-id",
                        comment: "",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .photo,
                        mediaURL: "https://picsum.photos/200/300"
                    ),
                    Media(
                        id: "3",
                        catId: id,
                        userId: "test-user-id",
                        comment: "",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .photo,
                        mediaURL: "https://picsum.photos/200/300"
                    ),
                    Media(
                        id: "4",
                        catId: id,
                        userId: "test-user-id",
                        comment: "",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .photo,
                        mediaURL: "https://picsum.photos/200/300"
                    ),
                    Media(
                        id: "5",
                        catId: id,
                        userId: "test-user-id",
                        comment: "",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .video,
                        mediaURL: "https://media.w3.org/2010/05/sintel/trailer.mp4"
                    ),
                    Media(
                        id: "6",
                        catId: id,
                        userId: "test-user-id",
                        comment: "",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .video,
                        mediaURL: "https://media.w3.org/2010/05/bunny/trailer.mp4"
                    ),
                    Media(
                        id: "7",
                        catId: id,
                        userId: "test-user-id",
                        comment: "",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .video,
                        mediaURL: "https://media.w3.org/2010/05/video/movie_300.mp4"
                    ),
                    Media(
                        id: "8",
                        catId: id,
                        userId: "test-user-id",
                        comment: "",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .video,
                        mediaURL: "https://media.w3.org/2010/05/sintel/trailer.mp4"
                    ),
                    Media(
                        id: "9",
                        catId: id,
                        userId: "test-user-id",
                        comment: "",
                        thumbnailURL: "https://picsum.photos/200/300",
                        mediaType: .video,
                        mediaURL: "https://media.w3.org/2010/05/bunny/trailer.mp4"
                    )
                ]
            )
        }
    )
}
