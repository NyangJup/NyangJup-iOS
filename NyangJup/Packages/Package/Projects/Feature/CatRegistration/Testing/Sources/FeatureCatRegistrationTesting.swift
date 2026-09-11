import SwiftUI

import DomainCatsInterface
import FeatureCatRegistrationInterface

public extension CatRegistrationFactory {
    static let test = Self { _, delegate in
        let delegate = delegate as? CatRegistrationDelegate

        return AnyView(
            VStack(spacing: 16) {
                ContentUnavailableView(
                    "CatRegistration 테스트 대역",
                    systemImage: "cat"
                )

                Button("닫기") {
                    delegate?.send(.close)
                }
            }
        )
    }
}
