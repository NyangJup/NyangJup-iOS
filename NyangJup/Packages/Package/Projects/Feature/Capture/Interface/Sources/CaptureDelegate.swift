import Foundation

import CoreCameraInterface
import FeatureCommonInterface

public struct CaptureDelegate: FeatureDelegate, Sendable {
    public enum Action: Sendable {
        case captured(CapturedMedia)
        case close
    }

    public let send: @MainActor @Sendable (Action) -> Void

    public init(send: @escaping @MainActor @Sendable (Action) -> Void) {
        self.send = send
    }
}
