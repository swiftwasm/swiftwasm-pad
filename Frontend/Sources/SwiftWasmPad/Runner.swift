import CombineShim
import JavaScriptKit
import ChibiLink

class Runner: ObservableObject {
    private let compilerAPI: CompilerAPI
    private let fileSystem = NodeFileSystem(object: swiftExport.sharedFs.object!)
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
    var isSharedLibraryDownloading: Bool { return !_isSharedLibraryDownloaded }
    let objectWillChange: AnyPublisher<Void, Never>
    
    let sharedLibrary = "/tmp/library.so.wasm"
    let linker = Linker()

    init(compilerAPI: CompilerAPI) {
        self.compilerAPI = compilerAPI
        objectWillChange = _objectWillChange.eraseToAnyPublisher()
        compilerAPI.sharedLibrary()
            .sink(
                receiveCompletion: { completion in
                    guard case let .failure(error) = completion else { return }
                    console.error(String(describing: error))
                },
                receiveValue: { [unowned self] arrayBuffer in
                    let Uint8Array = JSObjectRef.global.Uint8Array.function!
                    let buffer = Uint8Array.new(arrayBuffer)
                    self.linker.writeInput(self.sharedLibrary, buffer: arrayBuffer)
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
                try self.linkObjects(["/tmp/main.o": $0])
            }
            .switchToLatest()
            .flatMap {
                WebAssembly.runWasm($0).mapError { _ -> Error in }
            }
            .eraseToAnyPublisher()
            .map { _ in return Result<Void, Error>.success(()) }
            .catch { error in Just(.failure(error)) }
            .sink(receiveValue: { result in
                switch result {
                case .success: break
                case .failure(let error):
                    console.error(String(describing: error))
                }
                self._isRunning = false
            })
            .store(in: &cancellables)
    }
    func run(_ code: String) {
        guard isRunnable else { return }
        EventBus.flush.send()
        _isRunning = true
        execution.send(code)
    }

    func linkObjects(_ inputs: [String: JSObjectRef]) throws -> Future<JSObjectRef, Error> {
        for (filename, arrayBuffer) in inputs {
            linker.writeInput(filename, buffer: arrayBuffer)
        }
        return linker.link(Array(inputs.keys) + [sharedLibrary])
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
