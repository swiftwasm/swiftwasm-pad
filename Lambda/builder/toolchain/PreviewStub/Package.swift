// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ModuleBuilder",
    dependencies: [
        .package(name: "Tokamak", url: "https://github.com/TokamakUI/Tokamak", .branch("main")),
    ],
    targets: [
        .target(name: "PreviewStub", dependencies: [
            .product(name: "TokamakShim", package: "Tokamak"),
        ]),
    ]
)
