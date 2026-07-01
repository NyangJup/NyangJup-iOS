import SwiftUI

@available(iOS 13.0, macOS 10.15, *)
public enum NJColor {
    public static func named(_ name: String) -> Color {
        Color(name, bundle: .module)
    }
}
