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

import TokamakPreview

struct MyApp: PreviewApp {
  var body: some Scene {
    WindowGroup("Tokamak Demo") {
      Counter(count: Count(value: 0), limit: 10)
    }
  }
}
MyApp.main()
