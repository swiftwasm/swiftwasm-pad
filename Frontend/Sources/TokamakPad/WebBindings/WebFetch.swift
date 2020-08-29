import JavaScriptKit

let _jsFetch = JSObjectRef.global.get("fetch").function!
public func fetch(_ url: String, options: [String: JSValueConvertible]) -> Promise {
    Promise(_jsFetch(url, options))!
}
