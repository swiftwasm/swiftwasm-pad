import JavaScriptKit

enum JSON {
    private static let object = JSObjectRef.global.JSON.object!
    static func stringify(_ dictionary: [String: String]) -> String {
        object.stringify!(dictionary.jsValue()).string!
    }

    static func parse(_ string: String) -> JSObjectRef {
        object.parse!(string).object!
    }
}
