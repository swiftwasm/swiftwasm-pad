import TokamakDOM
import CombineShim
import JavaScriptKit

struct Editor: View {
    @State var code: String
    @EnvironmentObject
    var runner: Runner

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            EditorPane(content: $code) {
                runner.run(code)
            }
            DynamicHTML("div", ["style": "flex-basis: 6px;"])
            VStack {
                PreviewPane()
                DynamicHTML("div", ["style": "flex-basis: 6px;"])
                ConsolePane()
            }
            .id("right-pane")
        }
        .id("panels")
    }
}

let initialTemplate = """
import TokamakShim
import JavaScriptKit

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

struct EditorApp: App {
    let runner = Runner(compilerAPI: CompilerAPI())
    var body: some Scene {
        WindowGroup("Tokamak Pad") {
            VStack {
                NavigationHeader()
                Editor(code: initialTemplate)
            }
            .id("root-stack")
            .environmentObject(runner)
        }
    }
}

EditorApp.main()
WebAssembly.installHook { (fd, buffer) in
    switch fd {
    case 1: EventBus.stdout.send(buffer)
    case 2: EventBus.stderr.send(buffer)
    default: break
    }
}
EventBus.mounted.send()
