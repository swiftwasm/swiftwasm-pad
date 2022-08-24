import AWSLambdaRuntime
import NIO
import Foundation

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

struct CompileError: Error, Codable {
    let stderr: String
    let statusCode: Int32
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

struct LambdaError: Error, CustomStringConvertible {
    var description: String
}

let handler = CompilerOutputHandler<Request> { _, request, completion in
    cleanModuleCache()
    let result = Result<ByteBuffer, Error> {
        do {
            let object = try toolchain.emitObject(for: request.mainCode)
            if ProcessInfo.processInfo.environment["LOCAL_LAMBDA_SERVER_ENABLED"] == nil {
                // AWS API Gateway rejects binary response, so encode it and decode at the gateway
                return ByteBuffer(data: object.base64EncodedData())
            } else {
                return ByteBuffer(data: object)
            }
        }
        catch let error as CompileError {
            let encoder = JSONEncoder()
            let data = try encoder.encode(error)
            let jsonStr = String(decoding: data, as: Unicode.UTF8.self)
            throw LambdaError(description: jsonStr)
        }
    }
    completion(result)
}

func cleanModuleCache() {
    let home = URL(fileURLWithPath: ProcessInfo.processInfo.environment["HOME"]!)
    let fm = FileManager.default
    let cacheDir = home.appendingPathComponent(".cache/clang/ModuleCache")
    if fm.fileExists(atPath: cacheDir.path) && ProcessInfo.processInfo.environment["LOCAL_LAMBDA_SERVER_ENABLED"] == nil {
        try! FileManager.default.removeItem(at: cacheDir)
    }
}

Lambda.run(handler)
