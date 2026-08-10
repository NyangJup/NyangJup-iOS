// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "NJPackage",
    platforms: [.iOS(.v26), .macOS(.v14)],
    products: [
        // MARK: - Feature Products
        .library(
            name: "FeatureCommon",
            targets: ["FeatureCommon", "FeatureCommonInterface", "FeatureCommonTesting"]
        ),
        .library(
            name: "FeatureHome",
            targets: ["FeatureHome", "FeatureHomeInterface", "FeatureHomeTesting"]
        ),
        .library(
            name: "FeatureCapture",
            targets: ["FeatureCapture", "FeatureCaptureInterface", "FeatureCaptureTesting"]
        ),
        .library(
            name: "FeatureRelayCat",
            targets: ["FeatureRelayCat", "FeatureRelayCatInterface", "FeatureRelayCatTesting"]
        ),
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
            name: "CoreImageLoader",
            targets: ["CoreImageLoader", "CoreImageLoaderInterface", "CoreImageLoaderTesting"]
        ),
        .library(
            name: "CoreNetwork",
            targets: ["CoreNetwork", "CoreNetworkInterface", "CoreNetworkTesting"]
        ),
        .library(
            name: "CoreCamera",
            targets: ["CoreCamera", "CoreCameraInterface", "CoreCameraTesting"]
        ),
        .library(
            name: "CoreVideo",
            targets: ["CoreVideoInterface"]
        ),
        .library(
            name: "CoreAds",
            targets: ["CoreAds", "CoreAdsInterface"]
        ),
        // MARK: - Shared Products
        .library(
            name: "SharedDesign",
            targets: ["SharedDesign", "SharedDesignTesting"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "6.2.4"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", .upToNextMajor(from: "13.0.0")),
    ],
    targets: [
        .executableTarget(name: "ModuleGeneratorTool"),

        // MARK: - Feature Targets
        .target(
            name: "FeatureCommonInterface",
            dependencies: [],
            path: "Projects/Feature/FeatureCommon/Interface/Sources"
        ),
        .target(
            name: "FeatureCommon",
            dependencies: [
                .feature(module: .common, target: .interface)
            ],
            path: "Projects/Feature/FeatureCommon/Sources"
        ),
        .target(
            name: "FeatureCommonTesting",
            dependencies: [],
            path: "Projects/Feature/FeatureCommon/Testing/Sources"
        ),
        .testTarget(
            name: "FeatureCommonTests",
            dependencies: [
                .feature(module: .common, target: .feature),
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Projects/Feature/FeatureCommon/Tests"
        ),
        .target(
            name: "FeatureHomeInterface",
            dependencies: [
                .domain(module: .media, target: .interface),
                .feature(module: .common, target: .interface)
            ],
            path: "Projects/Feature/Home/Interface/Sources"
        ),
        .target(
            name: "FeatureHome",
            dependencies: [
                .domain(module: .cats, target: .interface),
                .domain(module: .media, target: .interface),
                .domain(module: .profile, target: .interface),
                .core(module: .imageLoader, target: .interface),
                .core(module: .ads, target: .interface),
                .shared(module: .design, target: .feature),
                .feature(module: .common, target: .interface),
                .feature(module: .home, target: .interface),
                .feature(module: .capture, target: .interface),
                .feature(module: .relayCat, target: .interface)
            ],
            path: "Projects/Feature/Home/Sources"
        ),
        .target(
            name: "FeatureHomeTesting",
            dependencies: [],
            path: "Projects/Feature/Home/Testing/Sources"
        ),
        .testTarget(
            name: "FeatureHomeTests",
            dependencies: [
                .feature(module: .home, target: .feature),
                .domain(module: .cats, target: .testing),
                .domain(module: .media, target: .testing),
                .domain(module: .profile, target: .testing),
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Projects/Feature/Home/Tests"
        ),
        .target(
            name: "FeatureCaptureInterface",
            dependencies: [
                .feature(module: .common, target: .interface),
                .core(module: .camera, target: .interface),
                .domain(module: .cats, target: .interface),
                .domain(module: .media, target: .interface)
            ],
            path: "Projects/Feature/Capture/Interface/Sources"
        ),
        .target(
            name: "FeatureCapture",
            dependencies: [
                .shared(module: .design, target: .feature),
                .feature(module: .common, target: .interface),
                .feature(module: .capture, target: .interface),
                .core(module: .camera, target: .interface),
                .core(module: .video, target: .interface),
                .domain(module: .cats, target: .interface),
                .domain(module: .media, target: .interface)
            ],
            path: "Projects/Feature/Capture/Sources"
        ),
        .target(
            name: "FeatureCaptureTesting",
            dependencies: [
                .core(module: .camera, target: .interface)
            ],
            path: "Projects/Feature/Capture/Testing/Sources"
        ),
        .testTarget(
            name: "FeatureCaptureTests",
            dependencies: [
                .feature(module: .capture, target: .feature),
                .core(module: .camera, target: .testing),
                .domain(module: .media, target: .testing),
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Projects/Feature/Capture/Tests"
        ),
        .target(
            name: "FeatureRelayCatInterface",
            dependencies: [
                .domain(module: .media, target: .interface),
                .feature(module: .common, target: .interface)
            ],
            path: "Projects/Feature/RelayCat/Interface/Sources"
        ),
        .target(
            name: "FeatureRelayCat",
            dependencies: [
                .domain(module: .media, target: .interface),
                .core(module: .imageLoader, target: .interface),
                .core(module: .video, target: .interface),
                .shared(module: .design, target: .feature),
                .feature(module: .common, target: .interface),
                .feature(module: .capture, target: .interface),
                .feature(module: .relayCat, target: .interface)
            ],
            path: "Projects/Feature/RelayCat/Sources"
        ),
        .target(
            name: "FeatureRelayCatTesting",
            dependencies: [
                .feature(module: .relayCat, target: .interface)
            ],
            path: "Projects/Feature/RelayCat/Testing/Sources"
        ),
        .testTarget(
            name: "FeatureRelayCatTests",
            dependencies: [
                .feature(module: .relayCat, target: .feature),
                .domain(module: .media, target: .testing),
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Projects/Feature/RelayCat/Tests"
        ),
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
                .domain(module: .profile, target: .testing),
                .product(name: "Testing", package: "swift-testing")
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
                .domain(module: .media, target: .testing),
                .product(name: "Testing", package: "swift-testing")
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
                .domain(module: .media, target: .interface),
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Projects/Domain/Cats/Tests"
        ),
        // MARK: - Core Targets
        .target(
            name: "CoreImageLoaderInterface",
            dependencies: [],
            path: "Projects/Core/ImageLoader/Interface/Sources"
        ),
        .target(
            name: "CoreImageLoader",
            dependencies: [
                .core(module: .imageLoader, target: .interface)
            ],
            path: "Projects/Core/ImageLoader/Sources"
        ),
        .target(
            name: "CoreImageLoaderTesting",
            dependencies: [
                .core(module: .imageLoader, target: .interface)
            ],
            path: "Projects/Core/ImageLoader/Testing/Sources"
        ),
        .testTarget(
            name: "CoreImageLoaderTests",
            dependencies: [
                .core(module: .imageLoader, target: .feature),
                .core(module: .imageLoader, target: .interface),
                .core(module: .imageLoader, target: .testing),
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Projects/Core/ImageLoader/Tests"
        ),
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
                .core(module: .network, target: .testing),
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Projects/Core/Network/Tests"
        ),
        .target(
            name: "CoreCameraInterface",
            dependencies: [],
            path: "Projects/Core/Camera/Interface/Sources"
        ),
        .target(
            name: "CoreCamera",
            dependencies: [
                .core(module: .camera, target: .interface)
            ],
            path: "Projects/Core/Camera/Sources"
        ),
        .target(
            name: "CoreCameraTesting",
            dependencies: [
                .core(module: .camera, target: .interface)
            ],
            path: "Projects/Core/Camera/Testing/Sources"
        ),
        .testTarget(
            name: "CoreCameraTests",
            dependencies: [
                .core(module: .camera, target: .feature),
                .core(module: .camera, target: .testing),
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Projects/Core/Camera/Tests"
        ),
        .target(
            name: "CoreVideoInterface",
            dependencies: [],
            path: "Projects/Core/Video/Interface/Sources"
        ),
        .target(
            name: "CoreAdsInterface",
            dependencies: [],
            path: "Projects/Core/Ads/Interface/Sources"
        ),
        .target(
            name: "CoreAds",
            dependencies: [
                .core(module: .ads, target: .interface),
                .product(
                    name: "GoogleMobileAds",
                    package: "swift-package-manager-google-mobile-ads"
                )
            ],
            path: "Projects/Core/Ads/Sources"
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
                .shared(module: .design, target: .testing),
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Projects/Shared/Design/Tests"
        ),
    ]
)

// MARK: - Module
enum Module {
    enum Feature: String {
        case common = "Common"
        case capture = "Capture"
        case home = "Home"
        case relayCat = "RelayCat"
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
        case imageLoader = "ImageLoader"
        case camera = "Camera"
        case network = "Network"
        case video = "Video"
        case ads = "Ads"
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
