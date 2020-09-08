import TokamakStaticHTML
import TokamakCore
import JavaScriptKit
import CombineShim

struct EditorPane: View {
    
    final class State: ObservableObject {
        let textBinding: Binding<String>
        let onRun: () -> Void
        init(textBinding: Binding<String>,
             onRun: @escaping () -> Void) {
            self.textBinding = textBinding
            self.onRun = onRun
        }

        var editorRef: JSObjectRef?
        var observedNodeRef: JSObjectRef?
        
        lazy var onChange = JSClosure { [weak self] _ in
            console.log("Received event on change")
            guard let editor = self?.editorRef else {
                console.log("Failed to emit event")
                return .undefined
            }
            let newContent = editor.getValue!().string!
            self?.textBinding.wrappedValue = newContent
            return .undefined
        }
        
        var cancellables: [AnyCancellable] = []
    }
    
    @StateObject private var state: State
    
    init(content: Binding<String>, onRun: @escaping () -> Void) {
        self._state = StateObject(
            wrappedValue: State(textBinding: content, onRun: onRun)
        )
    }

    var body: some View {
        HTML("div", ["id": "editor-pane"]) {
            RunButton(action: state.onRun)
                .id("run-button")
        }
        .bindKey(.ctrlAndEnter) {
            state.onRun()
        }
        ._domRef($state.observedNodeRef)
        ._onMount { mountCodeMirror() }
    }
    
    func mountCodeMirror() {
        let CodeMirror = swiftExport.CodeMirror.function!
        guard let mountTarget = state.observedNodeRef else {
            console.log("\(#function) is called before mounted")
            return
        }
        let options: [String: JSValueConvertible] = [
            "autoCloseBrackets": true,
            "matchBrackets": true,
            "tabSize": 2,
            "lineWrapping": true,
            "indentUnit": 2,
            "mode": "swift",
            "theme": "lucario",
            "value": state.textBinding.wrappedValue,
        ]
        EventBus.mounted.first()
            .sink(receiveValue: {
                let editor = CodeMirror.new(mountTarget, options)
                state.editorRef = editor
                _ = editor.on!("change", state.onChange)
                _ = editor.focus!()
            })
            .store(in: &state.cancellables)
    }
}
