import Foundation

struct InteractivePrompt {
    func askModuleSpec() throws -> ModuleSpec {
        let layer = try askLayer(title: "Select layer")
        let name = try askName("Enter module name")

        return ModuleSpec(
            layer: layer,
            name: name
        )
    }

    private func askLayer(title: String) throws -> ModuleLayer {
        print(title)

        for (index, layer) in ModuleLayer.allCases.enumerated() {
            print("  \(index + 1)) \(layer.rawValue)")
        }

        print("Enter number: ", terminator: "")

        guard
            let input = readLine(),
            let number = Int(input),
            ModuleLayer.allCases.indices.contains(number - 1)
        else {
            throw PromptError.invalidInput
        }

        return ModuleLayer.allCases[number - 1]
    }

    private func askName(_ question: String) throws -> String {
        print("\(question): ", terminator: "")

        guard let input = readLine() else {
            throw PromptError.invalidInput
        }

        let name = input.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            throw PromptError.invalidInput
        }
        
        return name.prefix(1).uppercased() + name.dropFirst()
    }
}

enum PromptError: Error {
    case invalidInput
}
