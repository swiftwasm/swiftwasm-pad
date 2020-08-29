import TokamakDOM
import TokamakStaticHTML

struct RunButton: View {
    let action: () -> Void

    var body: some View {
        Button("RUN", action: action)
    }
}
