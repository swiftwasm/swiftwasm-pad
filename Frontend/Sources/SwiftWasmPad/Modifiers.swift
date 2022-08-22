import TokamakDOM
@_spi(TokamakCore) import TokamakCore
import JavaScriptKit

struct _AttributeSetterView<Content: View>: View {
    @State var targetRef: JSObject? = nil
    let content: Content
    let key: String
    let value: String
    var append: Bool = false

    var body: some View {
        content
            ._domRef($targetRef)
            ._onMount {
                var newValue = value
                if append {
                    if let oldValue = targetRef?[key].string {
                        newValue += " " + oldValue
                    }
                }
                targetRef?[key] = .string(newValue)
            }
    }
}

extension View {
    func id(_ value: String) -> some View {
        _AttributeSetterView(content: self, key: "id", value: value)
    }

    func `class`(_ value: String) -> some View {
        _AttributeSetterView(content: self, key: "class", value: value, append: true)
    }
}
