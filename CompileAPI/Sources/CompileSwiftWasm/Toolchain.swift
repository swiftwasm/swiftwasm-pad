import Foundation
import NIO

struct Toolchain {
    
    enum Error: Swift.Error {
        case failedToEncodeCode
    }
    
    let swiftCompiler: URL
    let previewStub: PreviewStub

    var sysroot: URL {
        swiftCompiler
            .deletingLastPathComponent() // bin
            .deletingLastPathComponent() // usr
            .appendingPathComponent("share")
            .appendingPathComponent("wasi-sysroot")
    }

    private func invokeSwiftc(arguments: [String]) throws {
        let process = Process()
        let stderrPipe = Pipe()
        process.launchPath = swiftCompiler.path
        process.arguments = arguments
        process.standardError = stderrPipe
        process.launch()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrStr = String(decoding: stderrData, as: Unicode.UTF8.self)
            throw CompileError(stderr: stderrStr, statusCode: process.terminationStatus)
        }
    }

    var includeArguments: [String] {
        previewStub.includes.flatMap {
            ["-I", $0.path]
        }
        + previewStub.modulemaps.flatMap {
            ["-Xcc", "-fmodule-map-file=\($0.path)"]
        }
    }

    func emitObject(for code: String) throws -> Data {
        let tempDirectory: URL = makeTemporalyDirectory()
        let tempInput = tempDirectory.appendingPathComponent("main.swift")
        let tempOutput: URL = tempDirectory.appendingPathComponent("main.o")

        var arguments = [
            "-emit-object",
            tempInput.path, "-o", tempOutput.path,
            "-target", "wasm32-unknown-wasi",
            "-sdk", sysroot.path,
            "-module-cache-path", tempDirectory.path
        ]
        arguments += includeArguments

        guard let inputData = code.data(using: .utf8) else {
            throw Error.failedToEncodeCode
        }
        try inputData.write(to: tempInput)
        try invokeSwiftc(arguments: arguments)
        return try Data(contentsOf: tempOutput)
    }

    func emitExecutable(for code: String) throws -> Data {
        let tempDirectory: URL = makeTemporalyDirectory()
        let tempInput = tempDirectory.appendingPathComponent("main.swift")
        let tempOutput: URL = tempDirectory.appendingPathComponent("main.wasm")

        var arguments = [
            tempInput.path, "-o", tempOutput.path,
            "-target", "wasm32-unknown-wasi",
            "-sdk", sysroot.path,
            "-module-cache-path", tempDirectory.path,
            "-module-name", "main",
            "-Xclang-linker", "-mexec-model=reactor",
            "-Xlinker", "--export=main",
        ]
        arguments += includeArguments
        arguments += [
          "-L\(previewStub.root.path)", "-lJavaScriptKit",
        ]

        guard let inputData = code.data(using: .utf8) else {
            throw Error.failedToEncodeCode
        }
        try inputData.write(to: tempInput)
        try invokeSwiftc(arguments: arguments)
        return try Data(contentsOf: tempOutput)
    }
}
