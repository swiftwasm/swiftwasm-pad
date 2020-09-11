import AWSLambdaRuntime
import NIO

struct Request: Codable {
    let mainCode: String
}

struct CompilerOutputHandler<In: Decodable>: LambdaHandler {
    typealias In = In
    typealias Out = ByteBuffer
    
    typealias Closure = (Lambda.Context, In, @escaping (Result<Out, Error>) -> Void) -> Void

    private let closure: Closure

    init(_ closure: @escaping Closure) {
        self.closure = closure
    }

    func handle(context: Lambda.Context, event: In, callback: @escaping (Result<Out, Error>) -> Void) {
        closure(context, event, callback)
    }
    
    func encode(allocator: ByteBufferAllocator, value: Out) throws -> ByteBuffer? {
        value
    }
}

import Foundation


func exec(_ launchPath: String, _ arguments: [String]) {
    let process = Process()
    process.launchPath = launchPath
    process.arguments = arguments
    process.launch()
    process.waitUntilExit()
}

func makeTemporalyDirectory() -> URL {
    let tempdir = URL(fileURLWithPath: NSTemporaryDirectory())
    let templatePath = tempdir.appendingPathComponent("tokamak-pad.XXXXXX")
    var template = [UInt8](templatePath.path.utf8).map({ Int8($0) }) + [Int8(0)]
    if mkdtemp(&template) == nil {
        fatalError("Failed to create temp directory")
    }
    return URL(fileURLWithPath: String(cString: template))
}

struct PreviewStub {
    let root: URL
    
    var includes: [URL] {
        [
            root.appendingPathComponent("wasm32-unknown-wasi"),
            root.appendingPathComponent("checkouts/JavaScriptKit/Sources/_CJavaScriptKit/include"),
            root.appendingPathComponent("checkouts/Runtime/Sources/CRuntime/include"),
        ]
    }
    
    var modulemaps: [URL] {
        [
            root.appendingPathComponent("checkouts/Runtime/Sources/CRuntime/include/module.modulemap"),
            root.appendingPathComponent("checkouts/JavaScriptKit/Sources/_CJavaScriptKit/include/module.modulemap"),
        ]
    }
}

struct CompileError: Error, Codable {
    let stderr: String
    let statusCode: Int32
}

struct Toolchain {
    
    enum Error: Swift.Error {
        case failedToEncodeCode
    }
    
    let swiftCompiler: URL
    let previewStub: PreviewStub
    let tempDirectory: URL = makeTemporalyDirectory()

    var sysroot: URL {
        swiftCompiler
            .deletingLastPathComponent() // bin
            .deletingLastPathComponent() // usr
            .appendingPathComponent("share")
            .appendingPathComponent("wasi-sysroot")
    }

    var tempOutput: URL {
        tempDirectory.appendingPathComponent("main.o")
    }

    func emitObject(for code: String) throws -> ByteBuffer {
        let tempInput = tempDirectory.appendingPathComponent("main.swift")

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
        let binary = try Data(contentsOf: tempOutput)
        let bytes = ByteBuffer(data: binary.base64EncodedData())
        return bytes
    }
}

let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let swiftc = Lambda.env("LAMBDA_SWIFTC").map(URL.init(fileURLWithPath: ))
    ?? cwd.appendingPathComponent("toolchain/usr/bin/swiftc")
let previewStub = Lambda.env("LAMBDA_PREVIEW_STUB_PACKAGE").map(URL.init(fileURLWithPath: ))
    ?? cwd.appendingPathComponent("PreviewStub")


let toolchain = Toolchain(
    swiftCompiler: swiftc,
    previewStub: PreviewStub(root: previewStub)
)

let handler = CompilerOutputHandler<Request> { _, request, completion in
    let result = Result<ByteBuffer, Error> {
        do { return try toolchain.emitObject(for: request.mainCode) }
        catch let error as CompileError {
            let encoder = JSONEncoder()
            let data = try encoder.encode(error)
            return ByteBuffer(data: data)
        }
    }
    completion(result)
}

Lambda.run(handler)
