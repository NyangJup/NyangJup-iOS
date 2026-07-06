import Testing
@testable import DomainProfileInterface
import DomainProfileTesting

@Test
func testClientFetchIndividualCodeReturnsSampleCode() {
    let code = ProfileClient.test.fetchIndividualCode("123")

    #expect(code == "NYANG-7K2P")
}

@Test
func testClientFetchProfileReturnsRequestedID() async throws {
    let profile = try await ProfileClient.test.fetchProfile("123")

    #expect(profile.id == "123")
    #expect(profile.nickname == "집사")
}

@Test
func testClientUpdateNicknameCompletes() async throws {
    let request = UpdateNicknameRequestDTO(
        id: "123",
        nickname: "새집사"
    )

    try await ProfileClient.test.updateNickname(request)
}
