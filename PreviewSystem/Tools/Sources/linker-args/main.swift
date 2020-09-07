import Foundation

func env(_ name: String) -> String? {
    guard let value = getenv(name) else {
        return nil
    }
    return String(cString: value)
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

let stub = PreviewStub(root: previewStub)
let arguments = stub.linkFiles.map(\.path)
print(arguments.joined(separator: " "))
