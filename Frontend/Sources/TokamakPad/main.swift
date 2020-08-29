import TokamakDOM
import OpenCombine

struct Editor: View {
    @State var code: String
    @ObservedObject
    var runner: Runner
    
    var body: some View {
        VStack {
            TextField("Code", text: $code)
            Button("Run") {
                runner.run(code)
            }
        }
    }
}

struct EditorApp: App {
    let runner = Runner(compilerAPI: CompilerAPI())
    var body: some Scene {
        WindowGroup("Counter Demo") {
            Editor(code: "print(1)", runner: runner)
        }
    }
}

EditorApp.main()
