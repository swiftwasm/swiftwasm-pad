// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "ModuleBuilder",
    dependencies: [
        .package(url: "https://github.com/TokamakUI/Tokamak", exact: "0.10.1"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", exact: "0.15.0"),
    ],
    targets: [
        .target(name: "PreviewStub", dependencies: [
            .product(name: "TokamakShim", package: "Tokamak"),
            .target(name: "TokamakPreview"),
        ]),
        .target(name: "Demo", dependencies: [
            .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
        ]),
        .target(name: "TokamakPreview", dependencies: [
            .product(name: "TokamakShim", package: "Tokamak"),
        ]),
    ]
)
