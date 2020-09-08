import CombineShim
import JavaScriptKit
import ChibiLink

class Runner: ObservableObject {
    private let compilerAPI: CompilerAPI
    private let fileSystem = NodeFileSystem(object: JSObjectRef.global.sharedFs.object!)
    private let execution = PassthroughSubject<String, Never>()
    private var cancellables: [AnyCancellable] = []
    private var _isRunning: Bool = false {
        didSet { _objectWillChange.send(()) }
    }
    private var _isSharedLibraryDownloaded: Bool = false {
        didSet { _objectWillChange.send(()) }
    }
    private let _objectWillChange = PassthroughSubject<Void, Never>()
    var isRunnable: Bool { !_isRunning && _isSharedLibraryDownloaded }
    let objectWillChange: AnyPublisher<Void, Never>
    
    let sharedLibrary = "/tmp/library.so.wasm"
    lazy var dumpFn = JSClosure { _ in
        print("isRunning: \(self._isRunning)")
        print("_isSharedLibraryDownloaded: \(self._isSharedLibraryDownloaded)")
        print("isRunnable: \(self.isRunnable)")
        return .undefined
    }

    init(compilerAPI: CompilerAPI) {
        self.compilerAPI = compilerAPI
        objectWillChange = _objectWillChange.eraseToAnyPublisher()
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
                    self._isSharedLibraryDownloaded = true
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
            .eraseToAnyPublisher()
            .map { _ in return Result<Void, Error>.success(()) }
            .catch { error in Just(.failure(error)) }
            .sink { result in
                switch result {
                case .success: break
                case .failure(let error):
                    print(error)
                }
                self._isRunning = false
            }
            .store(in: &cancellables)
        
        JSObjectRef.global.dumpState = .function(dumpFn)
    }
    func run(_ code: String) {
        guard !_isRunning else { return }
        EventBus.flush.send()
        _isRunning = true
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
        let exports = [
            "swjs_call_host_function",
            "swjs_prepare_host_function_call",
            "swjs_cleanup_host_function_call",
            "swjs_library_version",
        ]
        try performLinker(objects, outputStream: writer, exports: exports)

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
