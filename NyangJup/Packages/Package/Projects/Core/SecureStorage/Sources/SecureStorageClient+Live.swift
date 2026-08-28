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
    static let live: SecureStorageClient = SecureStorageClient(
        save: { value, key in
            let data = Data(value.utf8)
            let baseQuery = makeQuery(key: key)
            
            let updateAttributes: [CFString: Any] = [
                kSecValueData: data
            ]
            
            let updateStatus = SecItemUpdate(
                baseQuery as CFDictionary,
                updateAttributes as CFDictionary
            )
            
            if updateStatus == errSecSuccess { return }
            
            guard updateStatus == errSecItemNotFound else {
                throw SecureStorageError.keychainFailure(status: updateStatus)
            }
            
            var addQuery = baseQuery
            addQuery[kSecValueData] = data
            addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            
            guard addStatus == errSecSuccess else {
                throw SecureStorageError.keychainFailure(
                    status: addStatus
                )
            }
            
        },
        read: { key in
            var query = makeQuery(key: key)
            query[kSecReturnData] = kCFBooleanTrue
            query[kSecMatchLimit] = kSecMatchLimitOne
            
            var result: CFTypeRef?
            
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            if status == errSecItemNotFound { return nil }
            
            guard status == errSecSuccess else {
                throw SecureStorageError.keychainFailure(
                    status: status
                )
            }
            
            guard
                let data = result as? Data,
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
            let status = SecItemDelete(
                makeQuery(
                    key: key
                ) as CFDictionary
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
    
    private static func makeQuery(
            key: String,
        ) -> [CFString: Any] {
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: Bundle.main.bundleIdentifier ?? "com.colin.NyangJup",
                kSecAttrAccount: key
            ]
        }

}


