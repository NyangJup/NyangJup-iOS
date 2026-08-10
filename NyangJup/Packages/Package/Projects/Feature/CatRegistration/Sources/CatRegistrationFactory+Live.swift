import SwiftUI

import DomainCatsInterface
import DomainMediaInterface
import FeatureCatRegistrationInterface

public extension CatRegistrationFactory {
    static func live(catsClient: CatsClient, mediaClient: MediaClient) -> Self {
        Self { _, delegate in
            let delegate = delegate as? CatRegistrationDelegate

            return AnyView(
                CatRegistrationRootView(
                    catsClient: catsClient,
                    mediaClient: mediaClient,
                    onComplete: { cat in
                        delegate?.send(.complete(cat))
                    },
                    onClose: {
                        delegate?.send(.close)
                    }
                )
            )
        }
    }
}
