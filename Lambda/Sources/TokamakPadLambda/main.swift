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

struct Toolchain {
    
    enum Error: Swift.Error {
        case failedToEncodeCode
    }
    
    let swiftCompiler: URL
    var sysroot: URL {
        swiftCompiler
            .deletingLastPathComponent() // bin
            .deletingLastPathComponent() // usr
            .appendingPathComponent("share")
            .appendingPathComponent("wasi-sysroot")
    }
    
    let tempOutput = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("main.o")
    
    func command(_ launchPath: String, _ arguments: [String]) {
        let process = Process()
        process.launchPath = launchPath
        process.arguments = arguments
        process.launch()
        process.waitUntilExit()
    }
    
    func emitBinary(for code: String) throws -> ByteBuffer {
        let arguments = [
            "-", "-o", tempOutput.path,
            "-target", "wasm32-unknown-wasi",
            "-sdk", sysroot.path,
            "-Osize", "-whole-module-optimization"
        ]

        guard let inputData = code.data(using: .utf8) else {
            throw Error.failedToEncodeCode
        }

        let process = Process()
        process.launchPath = swiftCompiler.path
        process.arguments = arguments
        let stdinPipe = Pipe()
        stdinPipe.fileHandleForWriting.writeabilityHandler = { handle in
            handle.write(inputData)
            try! handle.close()
        }
        process.standardInput = stdinPipe
        process.launch()
        process.waitUntilExit()
        command("/Users/kateinoigakukun/.bin/wasm-strip", [tempOutput.path])
        let bytes = try ByteBuffer(data: Data(contentsOf: tempOutput))
        return bytes
    }
}

let toolchain = Toolchain(
    swiftCompiler: URL(fileURLWithPath: "/Users/kateinoigakukun/.swiftenv/versions/wasm-5.3-SNAPSHOT-2020-08-20-a/usr/bin/swiftc")
)

let handler = CompilerOutputHandler<Request> { _, request, completion in
    let result = Result {
        try toolchain.emitBinary(for: request.mainCode)
    }
    completion(result)
}

Lambda.run(handler)
