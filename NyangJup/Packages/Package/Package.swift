// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "NJPackage",
    platforms: [.iOS(.v26)],
    products: [
        // MARK: - Feature Products
        // MARK: - Domain Products
        // MARK: - Core Products
        // MARK: - Shared Products
        .library(
            name: "SharedDesign",
            targets: ["SharedDesign", "SharedDesignTesting"]
        ),
    ],
    targets: [
        .executableTarget(name: "ModuleGeneratorTool"),

        // MARK: - Feature Targets
        // MARK: - Domain Targets
        // MARK: - Core Targets
        // MARK: - Shared Targets
        .target(
            name: "SharedDesign",
            dependencies: [],
            path: "Projects/Shared/Design",
            exclude: ["Tests", "Testing"],
            sources: ["Sources"],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "SharedDesignTesting",
            dependencies: [],
            path: "Projects/Shared/Design/Testing/Sources"
        ),
        .testTarget(
            name: "SharedDesignTests",
            dependencies: [
                .shared(module: .design, target: .testing)
            ],
            path: "Projects/Shared/Design/Tests"
        ),
    ]
)

// MARK: - Module
enum Module {
    enum Feature: String {
        @available(*, unavailable)
        case placeholder = "__Placeholder"
    }

    enum Domain: String {
        @available(*, unavailable)
        case placeholder = "__Placeholder"
    }

    enum Core: String {
        @available(*, unavailable)
        case placeholder = "__Placeholder"
    }

    enum Shared: String {
        case design = "Design"
        @available(*, unavailable)
        case placeholder = "__Placeholder"
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
