import Foundation

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
