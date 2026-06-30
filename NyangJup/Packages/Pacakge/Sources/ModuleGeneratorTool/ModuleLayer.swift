import Foundation

enum ModuleLayer: String, CaseIterable {
    case feature = "Feature"
    case domain = "Domain"
    case core = "Core"
    case shared = "Shared"

    var hasInterface: Bool {
        switch self {
        case .feature, .domain, .core: true
        case .shared: false
        }
    }
    
    var dependencyHelperName: String {
        rawValue.prefix(1).lowercased() + rawValue.dropFirst()
    }
}
