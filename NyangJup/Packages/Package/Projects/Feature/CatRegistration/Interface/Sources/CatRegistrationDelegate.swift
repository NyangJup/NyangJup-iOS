import DomainCatsInterface
import FeatureCommonInterface

public struct CatRegistrationDelegate: FeatureDelegate, Sendable {
    public enum Action: Sendable {
        case complete(Cat)
        case close
    }

    public let send: @MainActor @Sendable (Action) -> Void

    public init(
        send: @escaping @MainActor @Sendable (Action) -> Void
    ) {
        self.send = send
    }
}
