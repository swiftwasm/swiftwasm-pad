import JavaScriptKit

struct Console {
    private let console = JSObjectRef.global.console.object!
    func log(_ v: JSValueConvertible) {
        _ = console.log!(v)
    }
    func error(_ v: JSValueConvertible) {
        _ = console.error!(v)
    }
}

let console = Console()
