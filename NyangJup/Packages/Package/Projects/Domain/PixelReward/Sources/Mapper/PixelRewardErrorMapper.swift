//
//  PixelRewardErrorMapper.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

import CoreNetworkInterface
import DomainPixelRewardInterface

enum PixelRewardErrorMapper {
    static func map(_ error: any Error) -> any Error {
        guard let networkError = error as? NetworkError else {
            return error
        }

        let response: APIErrorResponse?
        switch networkError {
        case let .authorization(value),
             let .badRequest(value),
             let .notFound(value),
             let .server(value),
             let .client(value):
            response = value
        default:
            response = nil
        }

        switch response?.code {
        case "AD_SESSION_CONFLICT":
            return PixelRewardError.sessionUnavailable
        case "AD_SESSION_NOT_FOUND":
            return PixelRewardError.sessionNotFound
        case "APP_ATTEST_REPLAY":
            return PixelRewardError.appAttestReplay
        case "INVALID_APP_ATTEST_CHALLENGE":
            return PixelRewardError.invalidChallenge
        default:
            return networkError
        }
    }
}
