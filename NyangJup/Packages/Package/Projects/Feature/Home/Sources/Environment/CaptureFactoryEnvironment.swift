import SwiftUI

import FeatureCaptureInterface

private struct CaptureFactoryKey: EnvironmentKey {
    static let defaultValue = CaptureFactory { _, _ in
        AnyView(EmptyView())
    }
}

public extension EnvironmentValues {
    var captureFactory: CaptureFactory {
        get { self[CaptureFactoryKey.self] }
        set { self[CaptureFactoryKey.self] = newValue }
    }
}
