import Foundation

// 사용자의 대화형 입력 결과를 한 번에 담는 값입니다.
// 이후 단계는 이 struct만 보고 폴더 생성과 Package.swift 수정을 수행합니다.
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

        if layer.hasTesting {
            targets.append("\(targetPrefix)Testing")
        }

        return targets
    }
}
