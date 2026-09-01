//
//  ISO8601DateParser.swift
//  NJPackage
//
//  Created by 정지훈 on 9/1/26.
//

import Foundation

import CoreNetworkInterface

enum ISO8601DateParser {
    static func parse(_ value: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: value) {
            return date
        }

        formatter.formatOptions.insert(.withFractionalSeconds)
        guard let date = formatter.date(from: value) else {
            throw NetworkError.decoding
        }
        return date
    }
}
