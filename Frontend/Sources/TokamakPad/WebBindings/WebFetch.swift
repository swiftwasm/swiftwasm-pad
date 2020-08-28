import JavaScriptKit

let _jsFetch = JSObjectRef.global.get("fetch").function!
public func postFetch(_ url: String, options: [String: JSValueConvertible]) -> Promise {
    Promise(_jsFetch(url, options))!
}
