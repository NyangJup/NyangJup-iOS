//
//  PixelRewardClient+Live.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

import Foundation

import CoreNetworkInterface
import DomainDeviceSecurityInterface
import DomainPixelRewardInterface

public extension PixelRewardClient {
    static func live(
        networkClient: NetworkClient,
        deviceSecurityClient: DeviceSecurityClient
    ) -> Self {
        Self(
            fetchBalance: {
                do {
                    let response: PixelRewardBalanceResponseDTO = try await networkClient.request(
                        PixelRewardEndpoint.balance
                    )
                    return PixelRewardBalance(balance: response.balance)
                } catch {
                    throw PixelRewardErrorMapper.map(error)
                }
            },
            createAdSession: {
                do {
                    let endpoint = PixelRewardEndpoint.createAdSession
                    let assertion = try await deviceSecurityClient.generateAssertion(
                        .adSession,
                        endpoint
                    )
                    let response: PixelRewardAdSessionResponseDTO = try await networkClient.request(
                        AppAttestProtectedEndpoint(
                            base: endpoint,
                            assertion: assertion
                        )
                    )
                    return PixelRewardAdSession(
                        sessionId: response.sessionId,
                        expiresAt: try ISO8601DateParser.parse(response.expiresAt)
                    )
                } catch {
                    throw PixelRewardErrorMapper.map(error)
                }
            },
            claimAdReward: { sessionId in
                do {
                    let endpoint = PixelRewardEndpoint.claimAdReward(sessionId: sessionId)
                    let assertion = try await deviceSecurityClient.generateAssertion(
                        .adReward,
                        endpoint
                    )
                    let response: PixelRewardBalanceResponseDTO = try await networkClient.request(
                        AppAttestProtectedEndpoint(
                            base: endpoint,
                            assertion: assertion
                        )
                    )
                    return PixelRewardBalance(balance: response.balance)
                } catch {
                    throw PixelRewardErrorMapper.map(error)
                }
            }
        )
    }
}
