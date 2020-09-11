import TokamakDOM
import CombineShim
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
        let encodeURIComponent = JSObjectRef.global.encodeURIComponent.function!
        let encodedCode = encodeURIComponent(code).string!
        let newPath = "\(location.pathname)?code=\(encodedCode)"
        let Object = JSObjectRef.global.Object.function!
        _ = JSObjectRef.global.history.object!.replaceState!(Object.new(), "", newPath)
        let promise = JSObjectRef.global.navigator.object!
            .clipboard.object!.writeText!(location.href)
        Promise(promise)!
            .catch { console.error($0) }
            .then { _ in
                _ = JSObjectRef.global.alert!("URL copied to clipboard")
                return .undefined
            }
    }
}

let initialTemplate = """
import TokamakShim

final class Count: ObservableObject {
  @Published var value: Int

  init(value: Int) { self.value = value }
}

struct Counter: View {
  @ObservedObject var count: Count

  let limit: Int

  @ViewBuilder public var body: some View {
    if count.value < limit {
      VStack {
        Button("Increment") { count.value += 1 }
        Text("\\(count.value)")
      }
      .onAppear { print("Counter.VStack onAppear") }
      .onDisappear { print("Counter.VStack onDisappear") }
    } else {
      VStack { Text("Limit exceeded") }
    }
  }
}

struct MyApp: App {
  var body: some Scene {
    WindowGroup("Tokamak Demo") {
      Counter(count: Count(value: 0), limit: 10)
    }
  }
}

import JavaScriptKit
import TokamakCore

let app = MyApp()

print("App Launched")


let document = JSObjectRef.global.document.object!
let div = document.createElement!("div").object!
guard let preview = document.getElementById!("preview-host").object else {
  fatalError("Failed to get preview host")
}
let rootEnvironment = EnvironmentValues()
_ = preview.appendChild!(div)
MyApp._launch(app, rootEnvironment, div)
"""


func queryCode() -> String? {
    let URLSearchParams = JSObjectRef.global.URLSearchParams.function!
    let params = URLSearchParams.new(location.search)
    let getter = params.get("get").function!
    let maybeCode = getter.apply(this: params, arguments: "code")
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
  let document = JSObjectRef.global.document.object!
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
