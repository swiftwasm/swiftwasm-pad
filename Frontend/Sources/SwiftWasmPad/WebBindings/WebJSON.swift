import JavaScriptKit

enum JSON {
    private static let object = JSObject.global.JSON.object!
    static func stringify(_ dictionary: [String: String]) -> String {
        object.stringify!(dictionary.jsValue()).string!
    }

    static func parse(_ string: String) -> JSObject {
        object.parse!(string).object!
    }
}
