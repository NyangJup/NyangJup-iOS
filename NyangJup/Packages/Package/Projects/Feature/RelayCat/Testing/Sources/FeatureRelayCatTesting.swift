import SwiftUI

import FeatureRelayCatInterface

public extension RelayCatFactory {
    static let test = Self { _, _ in
        AnyView(
            ContentUnavailableView(
                "RelayCat 테스트 대역",
                systemImage: "play.rectangle"
            )
        )
    }
}
