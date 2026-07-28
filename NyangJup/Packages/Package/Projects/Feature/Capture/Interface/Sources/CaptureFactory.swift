import SwiftUI

import DomainCatsInterface
import FeatureCommonInterface

public struct CaptureFactory: Factorable, Sendable {
    public var makeView: @MainActor @Sendable (FeatureConfiguration?, FeatureDelegate?) -> AnyView

    public init(
        makeView: @escaping @MainActor @Sendable (FeatureConfiguration?, FeatureDelegate?) -> AnyView,
    ) {
        self.makeView = makeView
    }
}

public struct CaptureConfiguration: FeatureConfiguration {
    public let showsModePicker: Bool
    public let cat: Cat?
    public let catId: String?
    public let editingMediaId: String?
    public let mediaComment: String?
    
    public init(
        showsModePicker: Bool,
        cat: Cat? = nil,
        catId: String? = nil,
        editingMediaId: String? = nil,
        mediaComment: String? = nil
    ) {
        self.showsModePicker = showsModePicker
        self.cat = cat
        self.catId = catId
        self.editingMediaId = editingMediaId
        self.mediaComment = mediaComment
    }
}

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
