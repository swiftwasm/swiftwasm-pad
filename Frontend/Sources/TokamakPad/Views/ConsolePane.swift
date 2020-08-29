import TokamakDOM
import TokamakStaticHTML
import CombineShim

class LogCollector: ObservableObject {
    struct Line: Identifiable {
        var id: String { value }
        let value: String
    }
    @Published var logStorage: [Line] = []
    var cancellables: [AnyCancellable] = []

    init() {
        EventBus.stdout
            .sink(receiveValue: { [weak self] output in
                self?.logStorage.append(Line(value: output))
            })
            .store(in: &cancellables)
        EventBus.flush
            .sink(receiveValue: { [weak self] in
                self?.logStorage = []
            })
            .store(in: &cancellables)
    }
}

struct ConsolePane: View {
    @StateObject var collector = LogCollector()

    var body: some View {
        ScrollView {
            ForEach(collector.logStorage) { line in
                HTML("span", content: line.value)
            }
            .id("log-list")
        }
        .padding(24.0)
        .background(Color(hex: "2b3e50")!)
        .id("console-pane")
    }
}
