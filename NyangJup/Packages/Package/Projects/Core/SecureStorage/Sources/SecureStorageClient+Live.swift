//
//  File.swift
//  NJPackage
//
//  Created by 정지훈 on 8/28/26.
//

import Foundation
import Security

import CoreSecureStorageInterface

public extension SecureStorageClient {
    static let live = keychain(
        service: Bundle.main.bundleIdentifier ?? "com.colin.NyangJup",
        operations: .live
    )
}

extension SecureStorageClient {
    static func keychain(
        service: String,
        operations: KeychainOperations
    ) -> SecureStorageClient {
        SecureStorageClient(
            save: { value, key in
                let data = Data(value.utf8)
                let baseQuery = makeQuery(key: key, service: service)

                let updateAttributes: [CFString: Any] = [
                    kSecValueData: data
                ]

                let updateStatus = operations.update(baseQuery, updateAttributes)

                if updateStatus == errSecSuccess { return }

                guard updateStatus == errSecItemNotFound else {
                    throw SecureStorageError.keychainFailure(status: updateStatus)
                }

                var addQuery = baseQuery
                addQuery[kSecValueData] = data
                addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

                let addStatus = operations.add(addQuery)

                guard addStatus == errSecSuccess else {
                    throw SecureStorageError.keychainFailure(
                        status: addStatus
                    )
                }
            },
            read: { key in
                var query = makeQuery(key: key, service: service)
                query[kSecReturnData] = kCFBooleanTrue
                query[kSecMatchLimit] = kSecMatchLimitOne

                let (status, data) = operations.copyMatching(query)
                if status == errSecItemNotFound { return nil }

                guard status == errSecSuccess else {
                    throw SecureStorageError.keychainFailure(
                        status: status
                    )
                }

                guard
                    let data,
                    let value = String(
                        data: data,
                        encoding: .utf8
                    )
                else {
                    throw SecureStorageError.invalidStoredValue
                }

                return value
            },
            delete: { key in
                let status = operations.delete(
                    makeQuery(key: key, service: service)
                )

                guard
                    status == errSecSuccess || status == errSecItemNotFound
                else {
                    throw SecureStorageError.keychainFailure(
                        status: status
                    )
                }
            }
        )
    }

    private static func makeQuery(
        key: String,
        service: String
    ) -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
    }
}

struct KeychainOperations: Sendable {
    var update: @Sendable ([CFString: Any], [CFString: Any]) -> OSStatus
    var add: @Sendable ([CFString: Any]) -> OSStatus
    var copyMatching: @Sendable ([CFString: Any]) -> (OSStatus, Data?)
    var delete: @Sendable ([CFString: Any]) -> OSStatus
}

extension KeychainOperations {
    static let live = KeychainOperations(
        update: { query, attributes in
            SecItemUpdate(
                query as CFDictionary,
                attributes as CFDictionary
            )
        },
        add: { query in
            SecItemAdd(query as CFDictionary, nil)
        },
        copyMatching: { query in
            var result: CFTypeRef?
            let status = SecItemCopyMatching(
                query as CFDictionary,
                &result
            )
            return (status, result as? Data)
        },
        delete: { query in
            SecItemDelete(query as CFDictionary)
        }
    )
}
