import TokamakDOM
import OpenCombine
import JavaScriptKit

struct MessageError: Error {
    let message: String
    let line: UInt
    init(message: String, line: UInt = #line) {
        self.message = message
        self.line = line
    }
}


func consoleLog(_ v: JSValueConvertible) {
    let console = JSObjectRef.global.console.object!
    _ = console.log!(v)
}

class Runner: OpenCombine.ObservableObject {
    let compilerAPI: CompilerAPI
    let execution = PassthroughSubject<String, Never>()
    var cancellables: [AnyCancellable] = []
    
    @OpenCombine.Published var stdout: String = ""

    init(compilerAPI: CompilerAPI) {
        self.compilerAPI = compilerAPI
        execution
            .mapError { _ -> Error in }
            .map { compilerAPI.compile(code: $0) }
            .switchToLatest()
            .map { WebAssembly.runWasm($0) }
            .switchToLatest()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        print(error)
                    case .finished: break
                    }
                },
                receiveValue: {}
            )
            .store(in: &cancellables)
        
    }
    func run(_ code: String) {
        execution.send(code)
    }
}

struct Editor: View {
    @State var code: String
    @ObservedObject
    var runner: Runner
    
    var body: some View {
        VStack {
            TextField("Code", text: $code) { changed in
            } onCommit: {}
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
