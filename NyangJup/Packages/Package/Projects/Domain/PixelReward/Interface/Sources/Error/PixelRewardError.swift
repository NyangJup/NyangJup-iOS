public enum PixelRewardError: Error, Equatable, Sendable {
    case sessionUnavailable
    case sessionNotFound
    case appAttestReplay
    case invalidChallenge
}
