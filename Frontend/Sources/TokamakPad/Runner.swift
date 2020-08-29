import CombineShim

class Runner: ObservableObject {
    let compilerAPI: CompilerAPI
    let execution = PassthroughSubject<String, Never>()
    var cancellables: [AnyCancellable] = []
    
    @Published var stdout: String = ""

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
