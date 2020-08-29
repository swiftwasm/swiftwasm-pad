import TokamakDOM
import OpenCombine
import JavaScriptKit

struct Editor: View {
    @State var code: String
    @ObservedObject
    var runner: Runner

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            EditorPane(content: $code)
            Button("Run") {
                runner.run(code)
            }
        }
        .id("editor-view")
    }
}

let initialTemplate = """
import TokamakDOM

struct ContentView: View {
  var body: some View {
    Text("Hello, world")
  }
}
"""

struct EditorApp: App {
    let runner = Runner(compilerAPI: CompilerAPI())
    var body: some Scene {
        WindowGroup("Counter Demo") {
            VStack {
                NavigationHeader()
                Editor(code: initialTemplate, runner: runner)
            }
            .id("root-stack")
        }
    }
}

EditorApp.main()
EventBus.mounted.send()
