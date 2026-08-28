//
//  SecureStorageError.swift
//  NJPackage
//
//  Created by 정지훈 on 8/28/26.
//

import Foundation

public enum SecureStorageError: Error, Equatable, Sendable {
    case invalidStoredValue
    case keychainFailure(status: Int32)
}
