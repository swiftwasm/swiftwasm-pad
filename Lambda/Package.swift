// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "TokamakPadLambda",
    platforms: [.macOS(.v10_13)],
    products: [
        .executable(name: "TokamakPadLambda", targets: ["TokamakPadLambda"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "0.1.0"),
    ],
    targets: [
        .target(name: "TokamakPadLambda", dependencies: [
            .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
        ]),
        .testTarget(
            name: "TokamakPadLambdaTests",
            dependencies: ["TokamakPadLambda"]),
    ]
)
