import CombineShim

class Runner: ObservableObject {
    private let compilerAPI: CompilerAPI
    private let execution = PassthroughSubject<String, Never>()
    private var cancellables: [AnyCancellable] = []
    private var _isRunning = CurrentValueSubject<Bool, Never>(false)
    var isRunning: Bool { _isRunning.value }
    var objectWillChange: AnyPublisher<Void, Never>

    init(compilerAPI: CompilerAPI) {
        self.compilerAPI = compilerAPI
        objectWillChange = _isRunning.map { _ in }
            .eraseToAnyPublisher()
        execution
            .mapError { _ -> Error in }
            .map { compilerAPI.compile(code: $0) }
            .switchToLatest()
            .map { WebAssembly.runWasm($0) }
            .switchToLatest()
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
}
