// swift-tools-version:5.6
import PackageDescription
let package = Package(
    name: "SwiftWasmPad",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(name: "SwiftWasmPad", targets: ["SwiftWasmPad"]),
    ],
    dependencies: [
        .package(name: "JavaScriptKit", url: "https://github.com/swiftwasm/JavaScriptKit", .exact("0.15.0")),
        .package(name: "Tokamak", url: "https://github.com/TokamakUI/Tokamak", .exact("0.10.1")),
        .package(name: "ChibiLink", url: "https://github.com/kateinoigakukun/chibi-link", .exact("1.2.0")),
    ],
    targets: [
        .executableTarget(
            name: "SwiftWasmPad",
            dependencies: [
                .target(name: "i64_polyfill"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "TokamakShim", package: "Tokamak"),
                .product(name: "ChibiLink", package: "ChibiLink"),
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "--import-undefined",
                    "-Xlinker", "--undefined=_provide_mode", "-Xlinker", "--undefined=writeOutput"
                ])
            ]),
        .target(name: "i64_polyfill"),
    ]
)
