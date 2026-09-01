struct PixelRewardBalanceResponseDTO: Decodable {
    let balance: Int64
}

struct PixelRewardAdSessionResponseDTO: Decodable {
    let sessionId: String
    let expiresAt: String
}
