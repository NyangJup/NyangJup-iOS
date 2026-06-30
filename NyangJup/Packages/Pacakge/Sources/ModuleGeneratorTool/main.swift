//
//  main.swift
//  Pacakge
//
//  Created by 정지훈 on 6/29/26.
//

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
    let spec = try InteractivePrompt().askModuleSpec()
    
    try ModuleGenerator(packagePath: packagePath).generate(spec)
    print("Generated \(spec.layer.rawValue)\(spec.name)")
} catch {
    print("Error: \(error)")
    exit(1)
}
