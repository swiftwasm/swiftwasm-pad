// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Tools",
    products: [
        .executable(name: "strip-debug", targets: ["strip-debug"])
    ],
    dependencies: [],
    targets: [
        .target(name: "strip-debug", dependencies: []),
    ]
)
