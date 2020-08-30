// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ModuleBuilder",
    dependencies: [
        // FIXME: Please replace upstream repo after #271 will be merged
        .package(name: "Tokamak", url: "https://github.com/kateinoigakukun/Tokamak", .branch("allow-mount-non-body")),
    ],
    targets: [
        .target(name: "PreviewStub", dependencies: [
            .product(name: "TokamakShim", package: "Tokamak"),
        ]),
    ]
)
