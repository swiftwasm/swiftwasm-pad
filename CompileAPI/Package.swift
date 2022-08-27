// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "CompileSwiftWasm",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(name: "CompileSwiftWasm", targets: ["CompileSwiftWasm"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.65.1"),
    ],
    targets: [
        .target(name: "CompileSwiftWasm", dependencies: [
            .product(name: "Vapor", package: "vapor"),
        ]),
    ]
)
