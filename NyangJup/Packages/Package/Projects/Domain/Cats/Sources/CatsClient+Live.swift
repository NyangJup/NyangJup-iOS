//
//  CatsClient+Live.swift
//  NJPackage
//
//  Created by 정지훈 on 7/2/26.
//

import Foundation

import CoreNetworkInterface
import DomainCatsInterface
import DomainDeviceSecurityInterface

public extension CatsClient {
    static func live(
        networkClient: NetworkClient,
        deviceSecurityClient: DeviceSecurityClient
    ) -> Self {
        Self(
            fetchCats: {
                let response: [CatResponseDTO] = try await networkClient.request(
                    CatsEndpoint.fetchCats
                )
                return response.map { $0.toEntity() }
            },
            createCat: { request in
                let response: CatResponseDTO = try await networkClient.request(
                    CatsEndpoint.createCat(request)
                )
                return response.toEntity()
            },
            updateCatProfile: { id, request in
                let response: CatResponseDTO = try await networkClient.request(
                    CatsEndpoint.updateCatProfile(id: id, request: request)
                )
                return response.toEntity()
            },
            fetchCatFeed: { id, cursor in
                let response: CatFeedResponseDTO = try await networkClient.request(
                    CatsEndpoint.fetchCatFeed(id: id, cursor: cursor)
                )
                return try response.toEntity()
            },
            deleteCat: { id in
                let _: EmptyResponse = try await networkClient.request(
                    CatsEndpoint.deleteCat(id: id)
                )
            },
            fetchPixelCat: { request in
                let endpoint = CatsEndpoint.fetchPixelCat(request)
                let assertion = try await deviceSecurityClient.generateAssertion(
                    .pixelGeneration,
                    endpoint
                )
                let response: PixelCatResponseDTO = try await networkClient.request(
                    AppAttestProtectedEndpoint(
                        base: endpoint,
                        assertion: assertion
                    )
                )
                return response.toEntity()
            }
        )
    }
}
