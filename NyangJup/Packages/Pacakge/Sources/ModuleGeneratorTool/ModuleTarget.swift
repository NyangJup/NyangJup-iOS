import Foundation

enum ModuleTarget: String, CaseIterable {
    case interface = "Interface"
    case feature = ""
    case testing = "Testing"
    case tests = "Tests"
    
    var manifestCaseName: String {
        switch self {
        case .interface:
            return "interface"
        case .feature:
            return "feature"
        case .testing:
            return "testing"
        case .tests:
            return "tests"
        }
    }

    var sourcePathComponent: String {
        switch self {
        case .interface:
            return "Interface/Sources"
        case .feature:
            return "Sources"
        case .testing:
            return "Testing/Sources"
        case .tests:
            return "Tests"
        }
    }
}
