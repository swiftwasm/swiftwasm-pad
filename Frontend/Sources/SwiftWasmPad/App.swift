import TokamakDOM
import OpenCombineShim
import JavaScriptKit
import struct TokamakStaticHTML.HTML

struct Editor: View {
    @State var code: String
    @EnvironmentObject
    var runner: Runner

    var body: some View {
        VStack {
            NavigationHeader(onShare: copyShareLink)
            HStack(alignment: .top, spacing: 0) {
                EditorPane(content: $code) {
                    runner.run(code)
                }
                HTML("div", ["style": "flex-basis: 6px;"])
                VStack {
                    PreviewPane()
                    HTML("div", ["style": "flex-basis: 6px;"])
                    ConsolePane()
                }
                .id("right-pane")
            }
            .id("panels")
        }
    }

    func copyShareLink() {
        let encodeURIComponent = JSObject.global.encodeURIComponent.function!
        let encodedCode = encodeURIComponent(code).string!
        let newPath = "\(location.pathname)?code=\(encodedCode)"
        let Object = JSObject.global.Object.function!
        _ = JSObject.global.history.object!.replaceState!(Object.new(), "", newPath)
        let promise = JSObject.global.navigator.object!
            .clipboard.object!.writeText!(location.href)
        Promise(promise)!
            .catch { console.error($0) }
            .then { _ in
                _ = JSObject.global.alert!("URL copied to clipboard")
                return .undefined
            }
    }
}

let initialTemplate = """
import TokamakShim

struct Counter: View {
  @State var count: Int = 0

  let limit: Int

  @ViewBuilder
  public var body: some View {
    if count < limit {
      VStack {
        Button("Increment") { count += 1 }
        Text("\\(count)")
      }
      .onAppear { print("Counter.VStack onAppear") }
      .onDisappear { print("Counter.VStack onDisappear") }
    } else {
      VStack { Text("Limit exceeded") }
    }
  }
}

import TokamakPreview
struct MyApp: PreviewApp {
  var body: some Scene {
    WindowGroup("Tokamak Demo") {
      Counter(limit: 10)
    }
  }
}
MyApp.main()
"""


func queryCode() -> String? {
    let URLSearchParams = JSObject.global.URLSearchParams.function!
    let params = URLSearchParams.new(location.search)
    let maybeCode = params.get!("code")
    return maybeCode.string
}

struct EditorApp: App {
    let runner = Runner(compilerAPI: CompilerAPI())
    let initial: String = queryCode() ?? initialTemplate
    var body: some Scene {
        WindowGroup("SwiftWasm Pad") {
            Editor(code: initial)
                .id("root-stack")
                .environmentObject(runner)
        }
    }
}

func removeLoader() {
  let document = JSObject.global.document.object!
  _ = document.getElementById!("loader").object!
    .parentNode.object!
    .removeChild!(document.getElementById!("loader"))
}

func appMain() {
    removeLoader()
    EditorApp.main()
    WebAssembly.installHook { (fd, buffer) in
        switch fd {
        case 1: EventBus.stdout.send(buffer)
        case 2: EventBus.stderr.send(buffer)
        default: break
        }
    }
    EventBus.mounted.send()
}
