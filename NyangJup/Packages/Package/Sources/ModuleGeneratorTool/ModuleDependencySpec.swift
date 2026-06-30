import Foundation

struct ModuleDependencySpec {
    let layer: ModuleLayer
    let moduleName: String
    let targetKind: ModuleTarget

    var enumCaseName: String {
        moduleName.prefix(1).lowercased() + moduleName.dropFirst()
    }

    var manifestExpression: String {
        ".\(layer.dependencyHelperName)(module: .\(enumCaseName), target: .\(targetKind.manifestCaseName))"
    }
}
