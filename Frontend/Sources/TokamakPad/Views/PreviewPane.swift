import TokamakDOM
import TokamakStaticHTML
import CombineShim


struct PreviewPane: View {

    var body: some View {
        ScrollView {
            Text("Preview")
        }
        .padding(24.0)
        .background(Color(hex: "2b3e50")!)
        .id("preview-pane")
    }
}
