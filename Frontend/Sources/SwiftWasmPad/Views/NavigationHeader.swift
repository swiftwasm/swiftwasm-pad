import TokamakDOM
import TokamakStaticHTML

struct NavigationHeader: View {
    @EnvironmentObject
    var runner: Runner

    var body: some View {
        HStack {
            Text("SwiftWasm")
                .font(.title)
                .padding()
            Spacer()
            if runner.isSharedLibraryDownloading {
                Text("Downloading Shared Library...")
                HTML("div", ["class": "lds-ring"]) {
                    HTML("div")
                    HTML("div")
                    HTML("div")
                    HTML("div")
                }
            }
        }
    }
}
