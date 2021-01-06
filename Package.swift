// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cache",
    products: [
        .library(
            name: "Cache",
            targets: [
                "Cache",
            ]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-log.git",
            from: "1.2.0"
        ),
        .package(
            url: "https://github.com/regexident/PseudoRandom.git",
            from: "0.1.0"
        ),
        .package(
            name: "Benchmark",
            url: "https://github.com/google/swift-benchmark.git",
            .branch("main")
        ),
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "0.3.0"
        ),
    ],
    targets: [
        .target(
            name: "Cache",
            dependencies: [
                .product(
                    name: "Logging",
                    package: "swift-log"
                )
            ]
        ),
        .target(
            name: "CacheKeyGenerators",
            dependencies: [
                "PseudoRandom",
            ]
        ),
        .testTarget(
            name: "CacheTests",
            dependencies: [
                "Cache",
                "CacheKeyGenerators",
            ]
        ),
        .target(
            name: "CacheBenchmarks",
            dependencies: [
                "Benchmark",
                "Cache",
                "CacheKeyGenerators",
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
            ]
        ),
    ]
)
