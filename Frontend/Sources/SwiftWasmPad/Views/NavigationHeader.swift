import TokamakDOM
import TokamakStaticHTML

struct NavigationHeader: View {
    @EnvironmentObject
    var runner: Runner
    
    @Environment(\.colorScheme)
    var colorScheme
    
    var onShare: () -> Void

    var body: some View {
        HStack {
            nativeLink("https://swiftwasm.org") {
                Text("SwiftWasm")
                    .font(.title)
                    .padding()
            }
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

            ShareButton(action: onShare)
            nativeLink("https://github.com/kateinoigakukun/swiftwasm-pad") {
                HTML("img", [
                    "src": colorScheme == .dark ? "GitHub-Mark-Light-64px.png" : "GitHub-Mark-64px.png",
                    "style": """
                    width: 32px; height: 32px;
                    """
                ])
                .padding()
            }
        }
    }
    
    func nativeLink<Content: View>(_ url: String, @ViewBuilder _ content: () -> Content) -> some View {
        HTML("a", [
            "href": url,
            "style": "text-decoration: none;",
            "target": "_blank",
            "rel": "noreferrer noopener",
        ], content: content)
    }
}
