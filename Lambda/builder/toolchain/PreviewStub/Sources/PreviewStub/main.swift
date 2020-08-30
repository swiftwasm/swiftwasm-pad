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
        Text("\(count.value)")
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
