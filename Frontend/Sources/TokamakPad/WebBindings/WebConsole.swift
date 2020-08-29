import JavaScriptKit

struct Console {
    private let console = JSObjectRef.global.console.object!
    func log(_ v: JSValueConvertible) {
        _ = console.log!(v)
    }
}

let console = Console()
