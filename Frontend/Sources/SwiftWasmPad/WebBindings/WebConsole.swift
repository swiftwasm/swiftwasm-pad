import JavaScriptKit

struct Console {
    private let console = JSObject.global.console.object!
    func log(_ v: ConvertibleToJSValue) {
        _ = console.log!(v)
    }
    func error(_ v: ConvertibleToJSValue) {
        _ = console.error!(v)
    }
}

let console = Console()
