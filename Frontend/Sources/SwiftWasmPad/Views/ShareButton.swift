import TokamakDOM
import TokamakStaticHTML
import JavaScriptKit

struct ShareButton: View {
    let action: () -> Void

    var body: some View {
        let attributes: [HTMLAttribute: String] = [
            "id": "share-button",
            "class": "button",
        ]
        return DynamicHTML("button", attributes, listeners: ["click": onClick]) {
            HTML("span") { Text("Share").foregroundColor(.white) }
        }
    }
    
    func onClick(_: JSObject) {
        action()
    }
}
