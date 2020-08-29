import TokamakDOM
import OpenCombine
import JavaScriptKit

struct Editor: View {
    @State var code: String

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            EditorPane(content: $code) {
                print("Run: " + code)
            }
            Color.white
            Color.white
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
                Editor(code: initialTemplate)
            }
            .id("root-stack")
            .environmentObject(runner)
        }
    }
}

EditorApp.main()
EventBus.mounted.send()
