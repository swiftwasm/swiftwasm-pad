import TokamakDOM
import TokamakStaticHTML
import JavaScriptKit

struct RunButton: View {
    let action: () -> Void
    
    @EnvironmentObject
    var runner: Runner

    var body: some View {
        let attributes: [HTMLAttribute: String] = [
            "id": "run-button",
            "class": "button \(runner.isRunnable ? "" : "disabled-button")",
        ]
        return DynamicHTML("button", attributes, listeners: ["click": onClick]) {
            HTML("span") { Text("RUN").foregroundColor(.white) }
        }
    }
    
    func onClick(_: JSObject) {
        action()
    }
}
