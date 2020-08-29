import TokamakDOM
import JavaScriptKit

struct _AttributeSetterView<Content: View>: View {
    @State var targetRef: JSObjectRef? = nil
    let content: Content
    let key: String
    let value: String
    

    var body: some View {
        content
            ._domRef($targetRef)
            ._onMount {
                targetRef?.set(key, .string(value))
            }
    }
}

extension View {
    func id(_ value: String) -> some View {
        _AttributeSetterView(content: self, key: "id", value: value)
    }
}
