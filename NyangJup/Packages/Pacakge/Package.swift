// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NJPackage",
    platforms: [.iOS(.v26)],
    products: [
        // MARK: - Feature Products
        // MARK: - Domain Products
        // MARK: - Core Products
        // MARK: - Shared Products
    ],
    targets: [
        .executableTarget(name: "ModuleGeneratorTool"),
        .plugin(
            name: "GenerateModulePlugin",
            capability: .command(
                intent: .custom(
                    verb: "generate-module",
                    description: "Generate a new module"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Generate module files and update Package.swift")
                ]
            ),
            dependencies: ["ModuleGeneratorTool"]
        ),

        // MARK: - Feature Targets
        // MARK: - Domain Targets
        // MARK: - Core Targets
        // MARK: - Shared Targets
    ]
)

// MARK: - Module
enum Module {
    enum Feature: String {
        case home = "Home"
    }

    enum Domain: String {
        case feed = "Fead"
    }

    enum Core: String {
        case network = "Network"
    }

    enum Shared: String {
        case design = "Design"
    }
    
    enum Target: String {
        case interface = "Interface"
        case feature = ""
        case tests = "Tests"
        case testing = "Testing"
        case example = "Example"
    }
}

extension Target.Dependency {
    static func feature(module: Module.Feature, target: Module.Target) -> Self {
        .target(name: "Feature\(module.rawValue)\(target.rawValue)")
    }

    static func domain(module: Module.Domain, target: Module.Target) -> Self {
        .target(name: "Domain\(module.rawValue)\(target.rawValue)")
    }

    static func core(module: Module.Core, target: Module.Target) -> Self {
        .target(name: "Core\(module.rawValue)\(target.rawValue)")
    }

    static func shared(module: Module.Shared, target: Module.Target) -> Self {
        .target(name: "Shared\(module.rawValue)\(target.rawValue)")
    }
}
