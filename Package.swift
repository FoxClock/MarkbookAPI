// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

//package variables
let packageName = "MarkbookAPI"

let package = Package(
    name: packageName,
    platforms: [
      .macOS(.v13),
      .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: packageName,
            targets: [packageName]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: packageName,
            path: "Sources/MarkbookAPI"
            ),
        .testTarget(
            name: "MarkbookAPIClientTests",
            dependencies: [
                "MarkbookAPI"
            ],
            path: "Tests/MarkbookAPIClientTests"
        ),
    ]
)