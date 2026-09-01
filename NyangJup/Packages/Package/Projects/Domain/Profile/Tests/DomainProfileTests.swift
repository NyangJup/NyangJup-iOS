import Testing
@testable import DomainProfileInterface
import DomainProfileTesting

@Test
func testClientFetchProfileReturnsSampleProfile() async throws {
    let profile = try await ProfileClient.test.fetchProfile()

    #expect(profile.individualCode == "A1B2C3")
    #expect(profile.nickname == "집사")
}

@Test
func testClientUpdateNicknameCompletes() async throws {
    let request = UpdateNicknameRequestDTO(
        nickname: "새집사"
    )

    try await ProfileClient.test.updateNickname(request)
}
