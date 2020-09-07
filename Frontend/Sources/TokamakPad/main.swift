import TokamakDOM
import CombineShim
import JavaScriptKit

struct Editor: View {
    @State var code: String
    @EnvironmentObject
    var runner: Runner

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            EditorPane(content: $code) {
                runner.run(code)
            }
            DynamicHTML("div", ["style": "flex-basis: 6px;"])
            VStack {
                PreviewPane()
                DynamicHTML("div", ["style": "flex-basis: 6px;"])
                ConsolePane()
            }
            .id("right-pane")
        }
        .id("panels")
    }
}

let initialTemplate = """
for i in 0..<100 {
    print("Hello, world!")
}
"""

struct EditorApp: App {
    let runner = Runner(compilerAPI: CompilerAPI())
    var body: some Scene {
        WindowGroup("Tokamak Pad") {
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
WebAssembly.installHook { (fd, buffer) in
    switch fd {
    case 1: EventBus.stdout.send(buffer)
    case 2: EventBus.stderr.send(buffer)
    default: break
    }
}
EventBus.mounted.send()
