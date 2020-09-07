import CombineShim
import JavaScriptKit
import ChibiLink

class Runner: ObservableObject {
    private let compilerAPI: CompilerAPI
    private let fileSystem = NodeFileSystem(object: JSObjectRef.global.sharedFs.object!)
    private let execution = PassthroughSubject<String, Never>()
    private var cancellables: [AnyCancellable] = []
    private var _isRunning = CurrentValueSubject<Bool, Never>(false)
    var isRunning: Bool { _isRunning.value }
    var objectWillChange: AnyPublisher<Void, Never>
    
    let sharedLibrary = "/tmp/library.so.wasm"

    init(compilerAPI: CompilerAPI) {
        self.compilerAPI = compilerAPI
        objectWillChange = _isRunning.map { _ in }
            .eraseToAnyPublisher()
        compilerAPI.sharedLibrary()
            .sink(
                receiveCompletion: { completion in
                    print(completion)
                },
                receiveValue: { [unowned self] arrayBuffer in
                    let Uint8Array = JSObjectRef.global.Uint8Array.function!
                    let buffer = Uint8Array.new(arrayBuffer)
                    self.fileSystem.writeFileSync(self.sharedLibrary, buffer: buffer)
                    print("library.so.wasm was downloaded")
                }
            )
            .store(in: &cancellables)
        execution
            .mapError { _ -> Error in }
            .map { compilerAPI.compile(code: $0) }
            .switchToLatest()
            .tryMap { [unowned self] in
                try self.linkObjects(["/tmp/main.o": $0]) {
                    WebAssembly.runWasm($0)
                }
            }
            .switchToLatest()
            .print()
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case let .failure(error):
                        print(error)
                    case .finished: break
                    }
                    self?._isRunning.value = false
                },
                receiveValue: { [weak self] in
                    self?._isRunning.value = false
                }
            )
            .store(in: &cancellables)
        
    }
    func run(_ code: String) {
        guard !_isRunning.value else { return }
        EventBus.flush.send()
        _isRunning.value = true
        execution.send(code)
    }

    func linkObjects<T>(_ inputs: [String: JSObjectRef], _ output: (JSObjectRef) -> T) throws -> T {
        let Uint8Array = JSObjectRef.global.Uint8Array.function!
        for (filename, arrayBuffer) in inputs {
            let buffer = Uint8Array.new(arrayBuffer)
            fileSystem.writeFileSync(filename, buffer: buffer)
        }

        let objects = Array(inputs.keys) + [sharedLibrary]
        let writer = OutputWriter()
        try performLinker(objects, outputStream: writer, exports: [])

        let createArrayBufferFromSwiftArray = JSObjectRef.global.createArrayBufferFromSwiftArray.function!
        return writer.bytes.withUnsafeBufferPointer { bufferPtr in
            let rawPtr = Int(bitPattern: bufferPtr.baseAddress!)
            let arrayBuffer = createArrayBufferFromSwiftArray(rawPtr, bufferPtr.count)
            return output(arrayBuffer.object!)
        }
    }

    class OutputWriter: OutputByteStream {
        private(set) var bytes: [UInt8] = []
        private(set) var currentOffset: Int = 0

        func write(_ bytes: [UInt8], at offset: Int) throws {
            for index in offset ..< (offset + bytes.count) {
                self.bytes[index] = bytes[index - offset]
            }
        }

        func write(_ bytes: ArraySlice<UInt8>) throws {
            self.bytes.append(contentsOf: bytes)
            currentOffset += bytes.count
        }

        func writeString(_ value: String) throws {
            bytes.append(contentsOf: value.utf8)
            currentOffset += value.utf8.count
        }
    }
}
