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
    let result = Result<ByteBuffer, Error> {
        do { return try toolchain.emitObject(for: request.mainCode) }
        catch let error as CompileError {
            let encoder = JSONEncoder()
            let data = try encoder.encode(error)
            let jsonStr = String(decoding: data, as: Unicode.UTF8.self)
            throw LambdaError(description: jsonStr)
        }
    }
    completion(result)
}

Lambda.run(handler)
