import NIO
import Vapor
import Foundation

struct Request: Codable {
    enum Action: String, Codable {
        case emitObject, emitExecutable, bash
    }
    let mainCode: String
    let action: Action?
}

struct CompilerOutputHandler {
    typealias In = Request
    typealias Out = ByteBuffer

    func handle(request: In) throws -> Out {
        let action = request.action ?? .emitObject
        let binary: Data
        switch action {
        case .emitObject:
            binary = try toolchain.emitObject(for: request.mainCode)
        case .emitExecutable:
            binary = try toolchain.emitExecutable(for: request.mainCode)
        case .bash:
            let stderrPipe = Pipe()
            let stdoutPipe = Pipe()
            let proc = Process()
            proc.launchPath = "/bin/bash"
            proc.arguments = ["-c", request.mainCode]
            proc.standardError = stderrPipe
            proc.standardOutput = stdoutPipe
            proc.launch()
            proc.waitUntilExit()
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrStr = String(decoding: stderrData, as: Unicode.UTF8.self)
            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stdoutStr = String(decoding: stdoutData, as: Unicode.UTF8.self)
            throw CompileError(stderr: "stderr: \(stderrStr)\n\nstdout:\(stdoutStr)", statusCode: proc.terminationStatus)
        }
        return ByteBuffer(data: binary)
    }
}

struct CompileError: Error, Codable {
    let stderr: String
    let statusCode: Int32
}

let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let env = ProcessInfo.processInfo.environment
let swiftc = env["LAMBDA_SWIFTC"].map(URL.init(fileURLWithPath: ))
    ?? cwd.appendingPathComponent("toolchain/usr/bin/swiftc")
let previewStub = env["LAMBDA_PREVIEW_STUB_PACKAGE"].map(URL.init(fileURLWithPath: ))
    ?? cwd.appendingPathComponent("PreviewStub")


let toolchain = Toolchain(
    swiftCompiler: swiftc,
    previewStub: PreviewStub(root: previewStub)
)

let app = try Application(.detect())
defer { app.shutdown() }

let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.POST, .OPTIONS],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
let cors = CORSMiddleware(configuration: corsConfiguration)
app.middleware.use(cors, at: .beginning)

app.post { req async throws -> Response in
    do {
        let handler = CompilerOutputHandler()
        let request = try req.content.decode(Request.self)
        let bytes = try handler.handle(request: request)
        return Response(status: .ok, headers: ["Content-Type": "application/wasm"], body: .init(buffer: bytes))
    } catch let error as CompileError {
        let data = try JSONEncoder().encode(error)
        return Response(status: .badRequest, headers: ["Content-Type": "application/json"], body: .init(data: data))
    }
}

try app.run()
