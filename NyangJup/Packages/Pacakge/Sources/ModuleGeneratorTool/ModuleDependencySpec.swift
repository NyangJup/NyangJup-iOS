import Foundation

// 새로 만들 모듈이 의존할 다른 모듈 정보입니다.
// 예: FeatureHome -> DomainFeedInterface
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
