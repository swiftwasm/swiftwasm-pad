import JavaScriptKit

let _jsFetch = JSObject.global.fetch.function!
public func fetch(_ url: String, options: [String: ConvertibleToJSValue]) -> Promise {
    Promise(_jsFetch(url, options.jsValue))!
}
