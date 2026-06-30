import Foundation

let arguments = CommandLine.arguments

guard let packagePathIndex = arguments.firstIndex(of: "--package-path"),
      arguments.indices.contains(packagePathIndex + 1)
else {
    print("Missing --package-path")
    exit(1)
}

let packagePath = arguments[packagePathIndex + 1]

do {
    let spec: ModuleSpec

    if let layer = ModuleLayer(arguments: arguments),
       let name = String.optionValue(named: "--name", in: arguments) {
        spec = ModuleSpec(
            layer: layer,
            name: name.prefix(1).uppercased() + name.dropFirst()
        )
    } else {
        spec = try InteractivePrompt().askModuleSpec()
    }
    
    try ModuleGenerator(packagePath: packagePath).generate(spec)
    print("Generated \(spec.layer.rawValue)\(spec.name)")
} catch {
    print("Error: \(error)")
    exit(1)
}

private extension ModuleLayer {
    init?(arguments: [String]) {
        guard let value = String.optionValue(named: "--layer", in: arguments) else {
            return nil
        }

        self.init(rawValue: value.prefix(1).uppercased() + value.dropFirst().lowercased())
    }
}

private extension String {
    static func optionValue(named name: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: name),
              arguments.indices.contains(index + 1)
        else {
            return nil
        }

        return arguments[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
