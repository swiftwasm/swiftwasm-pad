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

enum JSON {
    private static let object = JSObjectRef.global.JSON.object!
    static func stringify(_ dictionary: [String: String]) -> String {
        object.stringify!(dictionary.jsValue()).string!
    }

    static func parse(_ string: String) -> JSObjectRef {
        object.parse!(string).object!
    }
}

struct DataBuffer {
    private let buffer: JSObjectRef

    init(arrayBuffer: JSObjectRef) {
        self.buffer = arrayBuffer
    }

    func slice(from begin: Int, to end: Int? = nil) -> DataBuffer {
        if let end = end {
            return DataBuffer(arrayBuffer: buffer.slice!(begin, end).object!)
        } else {
            return DataBuffer(arrayBuffer: buffer.slice!(begin).object!)
        }
    }

    var byteLength: Int { Int(buffer.byteLength.number!) }

    static let Uint8Array = JSObjectRef.global.Uint8Array.function!

    var uint8: [UInt8] {
        let uint8Buffer = Self.Uint8Array.new(buffer)
        var _buffer = [UInt8]()
        let count = Int(uint8Buffer.length.number!)
        _buffer.reserveCapacity(count)
        for index in 0..<count {
            _buffer.append(UInt8(uint8Buffer[index].number!))
        }
        return _buffer
    }
}

struct JSError: Error {
    let value: JSValue
    init(value: JSValue) {
        self.value = value
    }
}

func futurefy(_ promise: Promise) -> Future<JSValue, JSError> {
    Future { resolver in
        promise
            .catch { error in
                resolver(.failure(JSError(value: error)))
            }
            
            .then { value in
                resolver(.success(value))
                return .undefined
            }
    }

}

func consoleLog(_ v: JSValueConvertible) {
    let console = JSObjectRef.global.console.object!
    _ = console.log!(v)
}

class CompilerAPI {
    func compile(code: String) -> AnyPublisher<JSObjectRef, Error> {
        let body = JSON.stringify(["mainCode": code])
        let options: [String: JSValueConvertible] = [
            "mode": "cors",
            "method": "POST",
            "body": body,
            "headers": [
                "Content-Type": "application/json"
            ],
        ]
        let promise = postFetch("http://dev-lambda.swiftwasm.org:8090/invoke", options: options)

        return futurefy(promise)
            .flatMap { response -> Future<JSValue, JSError> in
                let promise = response.object!.arrayBuffer!()
                return futurefy(Promise(promise)!)
            }
            .map { $0.object! }
            .mapError { error -> Error in
                MessageError(message: error.value.object!.message.string!)
            }
            .eraseToAnyPublisher()
            
    }
}

class WebAssembly {
    private static let Uint8Array = JSObjectRef.global.Uint8Array.function!
    private static let swiftExport = JSObjectRef.global.swiftExports.object!
    private static let execWasm = swiftExport.execWasm.function!

    static func runWasm(_ arrayBuffer: JSObjectRef) -> AnyPublisher<Void, Error> {
        let promise = Promise(execWasm(arrayBuffer))!
        return futurefy(promise).map { _ in }
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
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
