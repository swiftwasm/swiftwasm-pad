// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "ModuleBuilder",
    dependencies: [
        .package(name: "Tokamak", url: "https://github.com/TokamakUI/Tokamak", .exact("0.10.1")),
    ],
    targets: [
        .target(name: "PreviewStub", dependencies: [
            .product(name: "TokamakShim", package: "Tokamak"),
            .target(name: "TokamakPreview"),
        ]),
        .target(name: "TokamakPreview", dependencies: [
            .product(name: "TokamakShim", package: "Tokamak"),
        ]),
    ]
)
