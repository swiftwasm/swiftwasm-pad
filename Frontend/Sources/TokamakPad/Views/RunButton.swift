import TokamakDOM
import TokamakStaticHTML
import JavaScriptKit

struct RunButton: View {
    let action: () -> Void
    
    @EnvironmentObject
    var runner: Runner

    var body: some View {
        return DynamicHTML("button", [
            "id": "run-button",
            "disabled": runner.isRunning ? "true" : "",
        ], listeners: ["click": onClick]) {
            HTML("span") { Text("RUN") }
        }
    }
    
    func onClick(_: JSObjectRef) {
        action()
    }
}
