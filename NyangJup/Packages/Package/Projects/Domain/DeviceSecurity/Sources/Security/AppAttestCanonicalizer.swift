//
//  AppAttestCanonicalizer.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

import CryptoKit
import Foundation

import CoreNetworkInterface

enum AppAttestCanonicalizer {
    static func clientDataHash(
        challenge: Data,
        endpoint: any Endpoint
    ) throws -> Data {
        let body: Data
        if let requestBody = endpoint.body {
            do {
                body = try JSONEncoder().encode(requestBody)
            } catch {
                throw NetworkError.encoding
            }
        } else {
            body = Data()
        }

        return clientDataHash(
            challenge: challenge,
            method: endpoint.method,
            path: canonicalPath(for: endpoint),
            body: body
        )
    }

    static func clientDataHash(
        challenge: Data,
        method: HTTPMethod,
        path: String,
        body: Data
    ) -> Data {
        var canonical = Data()
        canonical.append(challenge)
        canonical.append(0)
        canonical.append(Data(method.rawValue.uppercased().utf8))
        canonical.append(0)
        canonical.append(Data(path.utf8))
        canonical.append(0)
        canonical.append(Data(SHA256.hash(data: body)))
        return Data(SHA256.hash(data: canonical))
    }

    private static func canonicalPath(for endpoint: any Endpoint) -> String {
        let path = endpoint.path.hasPrefix("/")
            ? String(endpoint.path.dropFirst())
            : endpoint.path
        return endpoint.baseURL.appendingPathComponent(path).path
    }
}
