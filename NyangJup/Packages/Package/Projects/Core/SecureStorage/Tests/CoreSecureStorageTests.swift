import Foundation
import Testing

import CoreSecureStorage
import CoreSecureStorageInterface

@Suite(.serialized)
struct CoreSecureStorageTests {
    private let client = SecureStorageClient.live

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
