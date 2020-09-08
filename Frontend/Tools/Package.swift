// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Tools",
    products: [
        .executable(name: "i64-polyfill-gen", targets: ["i64-polyfill-gen"]),
    ],
    targets: [
        .target(name: "i64-polyfill-gen"),
    ]
)
