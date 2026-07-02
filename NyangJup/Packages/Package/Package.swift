// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "NJPackage",
    platforms: [.iOS(.v26)],
    products: [
        // MARK: - Feature Products
        // MARK: - Domain Products
        .library(
            name: "DomainProfile",
            targets: ["DomainProfile", "DomainProfileInterface", "DomainProfileTesting"]
        ),
        .library(
            name: "DomainMedia",
            targets: ["DomainMedia", "DomainMediaInterface", "DomainMediaTesting"]
        ),
        .library(
            name: "DomainCats",
            targets: ["DomainCats", "DomainCatsInterface", "DomainCatsTesting"]
        ),
        // MARK: - Core Products
        .library(
            name: "CoreNetwork",
            targets: ["CoreNetwork", "CoreNetworkInterface", "CoreNetworkTesting"]
        ),
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
        .target(
            name: "DomainProfileInterface",
            dependencies: [
                .core(module: .network, target: .interface),
            ],
            path: "Projects/Domain/Profile/Interface/Sources"
        ),
        .target(
            name: "DomainProfile",
            dependencies: [
                .domain(module: .profile, target: .interface)
            ],
            path: "Projects/Domain/Profile/Sources"
        ),
        .target(
            name: "DomainProfileTesting",
            dependencies: [
                .domain(module: .profile, target: .interface),
                .core(module: .network, target: .interface)
            ],
            path: "Projects/Domain/Profile/Testing/Sources"
        ),
        .testTarget(
            name: "DomainProfileTests",
            dependencies: [
                .core(module: .network, target: .interface),
                .domain(module: .profile, target: .interface),
                .domain(module: .profile, target: .testing)
            ],
            path: "Projects/Domain/Profile/Tests"
        ),
        .target(
            name: "DomainMediaInterface",
            dependencies: [
                .core(module: .network, target: .interface)
            ],
            path: "Projects/Domain/Media/Interface/Sources"
        ),
        .target(
            name: "DomainMedia",
            dependencies: [
                .domain(module: .media, target: .interface)
            ],
            path: "Projects/Domain/Media/Sources"
        ),
        .target(
            name: "DomainMediaTesting",
            dependencies: [
                .domain(module: .media, target: .interface)
            ],
            path: "Projects/Domain/Media/Testing/Sources"
        ),
        .testTarget(
            name: "DomainMediaTests",
            dependencies: [
                .domain(module: .media, target: .interface),
                .domain(module: .media, target: .testing)
            ],
            path: "Projects/Domain/Media/Tests"
        ),
        .target(
            name: "DomainCatsInterface",
            dependencies: [
                .core(module: .network, target: .interface),
                .domain(module: .media, target: .interface)
            ],
            path: "Projects/Domain/Cats/Interface/Sources"
        ),
        .target(
            name: "DomainCats",
            dependencies: [
                .domain(module: .cats, target: .interface)
            ],
            path: "Projects/Domain/Cats/Sources"
        ),
        .target(
            name: "DomainCatsTesting",
            dependencies: [
                .core(module: .network, target: .interface),
                .domain(module: .cats, target: .interface),
                .domain(module: .media, target: .interface)
            ],
            path: "Projects/Domain/Cats/Testing/Sources"
        ),
        .testTarget(
            name: "DomainCatsTests",
            dependencies: [
                .domain(module: .cats, target: .interface),
                .domain(module: .cats, target: .testing),
                .domain(module: .media, target: .interface)
            ],
            path: "Projects/Domain/Cats/Tests"
        ),
        // MARK: - Core Targets
        .target(
            name: "CoreNetworkInterface",
            dependencies: [],
            path: "Projects/Core/Network/Interface/Sources"
        ),
        .target(
            name: "CoreNetwork",
            dependencies: [
                .core(module: .network, target: .interface)
            ],
            path: "Projects/Core/Network/Sources"
        ),
        .target(
            name: "CoreNetworkTesting",
            dependencies: [],
            path: "Projects/Core/Network/Testing/Sources"
        ),
        .testTarget(
            name: "CoreNetworkTests",
            dependencies: [
                .core(module: .network, target: .feature),
                .core(module: .network, target: .testing)
            ],
            path: "Projects/Core/Network/Tests"
        ),
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
                .shared(module: .design, target: .feature),
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
        case profile = "Profile"
        case media = "Media"
        case cats = "Cats"
        @available(*, unavailable)
        case placeholder = "__Placeholder"
    }

    enum Core: String {
        case network = "Network"
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
