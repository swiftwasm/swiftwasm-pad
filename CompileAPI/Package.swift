// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "CompileSwiftWasm",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(name: "CompileSwiftWasm", targets: ["CompileSwiftWasm"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "0.5.2"),
    ],
    targets: [
        .target(name: "CompileSwiftWasm", dependencies: [
            .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
        ]),
    ]
)
