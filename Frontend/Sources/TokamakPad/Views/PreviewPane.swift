import TokamakDOM
import TokamakStaticHTML
import CombineShim
import JavaScriptKit

class Previewer: ObservableObject {
    var cancellables: [AnyCancellable] = []
    
    var previewHost: JSObjectRef?

    init() {
        EventBus.flush
            .sink(receiveValue: { [weak self] in
                self?.previewHost?.innerHTML = .string("")
            })
            .store(in: &cancellables)
    }
}

struct PreviewPane: View {

    @StateObject var previewer = Previewer()

    var body: some View {
        VStack(alignment: .leading) {
            Text("Preview")
            HTML("div", ["id": "preview-host"])
                ._domRef($previewer.previewHost)
        }
        .background(Color(hex: "2b3e50")!)
        .id("preview-pane")
    }
}
