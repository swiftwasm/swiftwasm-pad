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

    func emitObject(for code: String) throws -> Data {
        let tempDirectory: URL = makeTemporalyDirectory()
        let tempInput = tempDirectory.appendingPathComponent("main.swift")
        let tempOutput: URL = tempDirectory.appendingPathComponent("main.o")

        var arguments = [
            "-emit-object",
            tempInput.path, "-o", tempOutput.path,
            "-target", "wasm32-unknown-wasi",
            "-sdk", sysroot.path
        ]

        arguments += previewStub.includes.flatMap {
            ["-I", $0.path]
        }
        
        arguments += previewStub.modulemaps.flatMap {
            ["-Xcc", "-fmodule-map-file=\($0.path)"]
        }

        guard let inputData = code.data(using: .utf8) else {
            throw Error.failedToEncodeCode
        }
        try inputData.write(to: tempInput)
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
        return try Data(contentsOf: tempOutput)
    }

    func emitExecutable(for code: String) throws -> Data {
        let tempDirectory: URL = makeTemporalyDirectory()
        let tempInput = tempDirectory.appendingPathComponent("main.swift")
        let tempOutput: URL = tempDirectory.appendingPathComponent("main.o")

        let arguments = [
            tempInput.path, "-o", tempOutput.path,
            "-target", "wasm32-unknown-wasi",
            "-sdk", sysroot.path
        ]

        guard let inputData = code.data(using: .utf8) else {
            throw Error.failedToEncodeCode
        }
        try inputData.write(to: tempInput)
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
        return try Data(contentsOf: tempOutput)
    }
}
