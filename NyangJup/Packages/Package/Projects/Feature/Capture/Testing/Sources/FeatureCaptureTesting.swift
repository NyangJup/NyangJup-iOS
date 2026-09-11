import Foundation
import SwiftUI

import CoreCameraInterface
import FeatureCaptureInterface

public extension CaptureFactory {
    static let test = Self { _, delegate in
        let delegate = delegate as? CaptureDelegate

        return AnyView(
            VStack(spacing: 16) {
                ContentUnavailableView(
                    "Capture 테스트 대역",
                    systemImage: "camera"
                )

                Button("닫기") {
                    delegate?.send(.close)
                }
            }
        )
    }
}
