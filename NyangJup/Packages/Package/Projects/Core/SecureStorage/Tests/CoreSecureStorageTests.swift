import Foundation
import Security
import Testing

@testable import CoreSecureStorage
import CoreSecureStorageInterface

@Suite(.serialized)
struct CoreSecureStorageTests {
    private let client: SecureStorageClient

    init() {
        let keychain = InMemoryKeychain()
        client = .keychain(
            service: "CoreSecureStorageTests",
            operations: keychain.operations
        )
    }

    @Test
    func savesAndReadsValue() throws {
        let key = makeUniqueKey()
        defer { try? client.delete(key) }

        try client.save("access-token", key)

        #expect(try client.read(key) == "access-token")
    }

    @Test
    func savingExistingKeyUpdatesValue() throws {
        let key = makeUniqueKey()
        defer { try? client.delete(key) }

        try client.save("old-token", key)
        try client.save("new-token", key)

        #expect(try client.read(key) == "new-token")
    }

    @Test
    func deletingValueRemovesIt() throws {
        let key = makeUniqueKey()
        defer { try? client.delete(key) }

        try client.save("access-token", key)
        try client.delete(key)

        #expect(try client.read(key) == nil)
    }

    @Test
    func readingMissingKeyReturnsNil() throws {
        let key = makeUniqueKey()
        defer { try? client.delete(key) }

        #expect(try client.read(key) == nil)
    }

    @Test
    func deletingMissingKeySucceeds() throws {
        let key = makeUniqueKey()

        try client.delete(key)
    }

    private func makeUniqueKey() -> String {
        "CoreSecureStorageTests.\(UUID().uuidString)"
    }
}

private final class InMemoryKeychain: @unchecked Sendable {
    private var values: [String: Data] = [:]

    var operations: KeychainOperations {
        KeychainOperations(
            update: { [self] query, attributes in
                guard
                    let key = key(from: query),
                    let data = attributes[kSecValueData] as? Data
                else {
                    return errSecParam
                }

                guard values[key] != nil else {
                    return errSecItemNotFound
                }

                values[key] = data
                return errSecSuccess
            },
            add: { [self] query in
                guard
                    let key = key(from: query),
                    let data = query[kSecValueData] as? Data
                else {
                    return errSecParam
                }

                values[key] = data
                return errSecSuccess
            },
            copyMatching: { [self] query in
                guard let key = key(from: query) else {
                    return (errSecParam, nil)
                }

                guard let data = values[key] else {
                    return (errSecItemNotFound, nil)
                }

                return (errSecSuccess, data)
            },
            delete: { [self] query in
                guard let key = key(from: query) else {
                    return errSecParam
                }

                guard values.removeValue(forKey: key) != nil else {
                    return errSecItemNotFound
                }

                return errSecSuccess
            }
        )
    }

    private func key(from query: [CFString: Any]) -> String? {
        guard
            let service = query[kSecAttrService] as? String,
            let account = query[kSecAttrAccount] as? String
        else {
            return nil
        }

        return "\(service).\(account)"
    }
}
