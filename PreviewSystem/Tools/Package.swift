// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Tools",
    products: [
        .executable(name: "strip-debug", targets: ["strip-debug"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "strip-debug"),
    ]
)
