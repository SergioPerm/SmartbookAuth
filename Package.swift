// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SmartbookAuth",
    defaultLocalization: "en",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SmartbookAuth",
            targets: ["SmartbookAuth"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", exact: Version("6.5.0")),
        .package(url: "https://github.com/mac-cain13/R.swift.git", from: Version("7.0.0")),
        .package(url: "https://github.com/SergioPerm/SmartbookAuth.git", from: Version("0.1.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SmartbookAuth",
            dependencies: [
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "RswiftLibrary", package: "R.swift"),
                .product(name: "SmartbookCore", package: "SmartbookCore"),
            ],
            path: "Sources",
            plugins: [.plugin(name: "RswiftGenerateInternalResources", package: "R.swift")]
        ),
        .testTarget(
            name: "SmartbookAuthTests",
            dependencies: ["SmartbookAuth"]
        ),
    ]
)
