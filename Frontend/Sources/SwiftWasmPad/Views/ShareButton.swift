import TokamakDOM
import TokamakStaticHTML
import JavaScriptKit

struct ShareButton: View {
    let action: () -> Void

    var body: some View {
        let attributes = [
            "id": "share-button",
            "className": "button",
        ]
        return DynamicHTML("button", attributes, listeners: ["click": onClick]) {
            HTML("span") { Text("Share").foregroundColor(.white) }
        }
    }
    
    func onClick(_: JSObjectRef) {
        action()
    }
}
