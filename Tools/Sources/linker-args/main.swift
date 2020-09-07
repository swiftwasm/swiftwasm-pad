import Foundation


func exec(_ launchPath: String, _ arguments: [String]) {
    let process = Process()
    process.launchPath = launchPath
    process.arguments = arguments
    process.launch()
    process.waitUntilExit()
}

func env(_ name: String) -> String? {
    guard let value = getenv(name) else {
        return nil
    }
    return String(cString: value)
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

let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let previewStub = env("LAMBDA_PREVIEW_STUB_PACKAGE").map(URL.init(fileURLWithPath: ))!

let linkerFlags = [
    "--export=swjs_call_host_function",
    "--export=swjs_prepare_host_function_call",
    "--export=swjs_cleanup_host_function_call",
    "--export=swjs_library_version",
    "--allow-undefined"
]

let stub = PreviewStub(root: previewStub)
let arguments = linkerFlags + stub.linkFiles.map(\.path)
print(arguments.joined(separator: " "))
