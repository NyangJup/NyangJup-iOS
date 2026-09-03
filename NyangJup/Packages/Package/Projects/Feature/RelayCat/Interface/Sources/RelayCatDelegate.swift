import DomainMediaInterface
import FeatureCommonInterface

public struct RelayCatDelegate: FeatureDelegate, Sendable {
    public enum Action: Sendable {
        case likeUpdated(mediaId: String, isLiked: Bool)
        case mediaUpdated(Media)
        case mediaDeleted(mediaId: String)
    }

    public let send: @MainActor @Sendable (Action) -> Void

    public init(send: @escaping @MainActor @Sendable (Action) -> Void) {
        self.send = send
    }
}
