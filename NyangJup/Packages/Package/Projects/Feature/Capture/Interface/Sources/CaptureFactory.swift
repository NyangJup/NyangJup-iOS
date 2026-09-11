import SwiftUI

import CoreCameraInterface
import DomainCatsInterface
import FeatureCommonInterface

public enum CaptureUsage: Sendable {
    case media
    case catRegistration
}

public struct CaptureFactory: Factorable, Sendable {
    public var makeView: @MainActor @Sendable (FeatureConfiguration?, FeatureDelegate?) -> AnyView

    public init(
        makeView: @escaping @MainActor @Sendable (FeatureConfiguration?, FeatureDelegate?) -> AnyView,
    ) {
        self.makeView = makeView
    }
}

public extension CaptureFactory {
    static let unimplemented = Self { _, _ in
        assertionFailure("CaptureFactory가 Environment에 주입되지 않았습니다.")
        return AnyView(EmptyView())
    }
}

public struct CaptureConfiguration: FeatureConfiguration {
    public let usage: CaptureUsage
    public let showsModePicker: Bool
    public let cat: Cat?
    public let catId: String?
    public let editingMediaId: String?
    public let mediaComment: String?
    
    public init(
        usage: CaptureUsage = .media,
        showsModePicker: Bool,
        cat: Cat? = nil,
        catId: String? = nil,
        editingMediaId: String? = nil,
        mediaComment: String? = nil
    ) {
        self.usage = usage
        self.showsModePicker = showsModePicker
        self.cat = cat
        self.catId = catId
        self.editingMediaId = editingMediaId
        self.mediaComment = mediaComment
    }
}

public extension EnvironmentValues {
    @Entry var captureFactory = CaptureFactory.unimplemented
}
