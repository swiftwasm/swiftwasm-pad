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
            root.appendingPathComponent(".build/wasm32-unknown-wasi/debug"),
            root.appendingPathComponent(".build/checkouts/JavaScriptKit/Sources/_CJavaScriptKit/include"),
            root.appendingPathComponent(".build/checkouts/Runtime/Sources/CRuntime/include"),
        ]
    }
    
    var modulemaps: [URL] {
        [
            root.appendingPathComponent(".build/checkouts/Runtime/Sources/CRuntime/include/module.modulemap"),
            root.appendingPathComponent(".build/checkouts/JavaScriptKit/Sources/_CJavaScriptKit/include/module.modulemap"),
        ]
    }
    
    var linkFiles: [URL] {
        let linkFileList = root.appendingPathComponent(".build/wasm32-unknown-wasi/debug/PreviewStub.product/Objects.LinkFileList")
        return try! String(contentsOf: linkFileList).split(separator: "\n")
            .filter { !$0.contains(".build/wasm32-unknown-wasi/debug/PreviewStub.build/main.swift.o") }
            .map {
                let path = $0.replacingOccurrences(of: "/home/work/PreviewStub", with: root.path)
                return URL(fileURLWithPath: path)
        }
    }
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
    
    func emitTokamakExecutable(for code: String) throws -> ByteBuffer {
        let linkerFlags = [
            "--export=swjs_call_host_function",
            "--export=swjs_prepare_host_function_call",
            "--export=swjs_cleanup_host_function_call",
            "--export=swjs_library_version",
            "--allow-undefined"
        ] + previewStub.linkFiles.map(\.path)
        var arguments = [
            "-", "-o", tempOutput.path,
            "-target", "wasm32-unknown-wasi",
            "-sdk", sysroot.path,
            "-Osize", "-whole-module-optimization"
        ]
        
        arguments += linkerFlags.flatMap {
            ["-Xlinker", $0]
        }
        arguments += previewStub.includes.flatMap {
            ["-I", $0.path]
        }

        arguments += previewStub.modulemaps.flatMap {
            ["-Xcc", "-fmodule-map-file=\($0.path)"]
        }

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
        let bytes = try ByteBuffer(data: Data(contentsOf: tempOutput))
        print("End of \(#function)")
        return bytes
    }
    
    func emitObject(for code: String) throws -> ByteBuffer {
        let arguments = [
//            "-emit-object",
            "-", "-o", tempDirectory.path,
            "-target", "wasm32-unknown-wasi",
            "-sdk", sysroot.path,
            "-Osize", "-whole-module-optimization",
            "-v"
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
        let bytes = try ByteBuffer(data: Data(contentsOf: tempDirectory))
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

//func mockResponse() throws -> ByteBuffer {
//    let tempOutput = URL(fileURLWithPath: #filePath)
//        .deletingLastPathComponent()
//        .deletingLastPathComponent()
//        .deletingLastPathComponent()
//        .appendingPathComponent("CounterDemo.wasm")
//    let bytes = try ByteBuffer(data: Data(contentsOf: tempOutput))
//    return bytes
//}

let handler = CompilerOutputHandler<Request> { _, request, completion in
    let result = Result {
        try toolchain.emitTokamakExecutable(for: request.mainCode)
//        try toolchain.emitObject(for: request.mainCode)
    }
    completion(result)
}

Lambda.run(handler)
