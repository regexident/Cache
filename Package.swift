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
        .testTarget(
            name: "CacheTests",
            dependencies: [
                "Cache",
            ]
        ),
    ]
)
