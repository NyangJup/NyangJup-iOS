import SwiftUI

@available(iOS 13.0, macOS 10.15, *)
public enum NJImage {
    public static func named(_ name: String) -> Image {
        Image(name, bundle: .module)
    }
}
