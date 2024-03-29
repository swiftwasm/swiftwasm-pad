import Foundation

struct PreviewStub {
    let root: URL
    var includes: [URL] {
        [
            root.appendingPathComponent("wasm32-unknown-wasi"),
            root.appendingPathComponent("checkouts/JavaScriptKit/Sources/_CJavaScriptKit/include"),
            root.appendingPathComponent("checkouts/JavaScriptKit/Sources/_CJavaScriptEventLoop/include"),
            root.appendingPathComponent("checkouts/OpenCombine/Sources/COpenCombineHelpers/include"),
        ]
    }
    
    var modulemaps: [URL] {
        [
            root.appendingPathComponent("checkouts/JavaScriptKit/Sources/_CJavaScriptKit/include/module.modulemap"),
            root.appendingPathComponent("checkouts/JavaScriptKit/Sources/_CJavaScriptEventLoop/include/module.modulemap"),
            root.appendingPathComponent("checkouts/OpenCombine/Sources/COpenCombineHelpers/include/module.modulemap"),
        ]
    }
}
