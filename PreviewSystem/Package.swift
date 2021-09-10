// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "ModuleBuilder",
    dependencies: [
        .package(name: "Tokamak", url: "https://github.com/TokamakUI/Tokamak", .revision("ba7af1d014201c9bcac09e934af158e81136a74c")),
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
