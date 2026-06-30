import Foundation

struct ModuleSpec {
    let layer: ModuleLayer
    let name: String

    var targetPrefix: String {
        "\(layer.rawValue)\(name)"
    }

    var modulePath: String {
        "Projects/\(layer.rawValue)/\(name)"
    }

    var enumCaseName: String {
        name.prefix(1).lowercased() + name.dropFirst()
    }

    var productTargets: [String] {
        var targets = [targetPrefix]

        if layer.hasInterface {
            targets.append("\(targetPrefix)Interface")
        }

        targets.append("\(targetPrefix)Testing")

        return targets
    }
}
