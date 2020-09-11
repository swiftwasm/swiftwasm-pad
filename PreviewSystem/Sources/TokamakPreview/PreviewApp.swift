import JavaScriptKit
import TokamakCore
import TokamakDOM

public protocol PreviewApp: App {}

extension PreviewApp {
  public static func main() {
    let app = Self()
    let document = JSObjectRef.global.document.object!
    let div = document.createElement!("div").object!
    guard let preview = document.getElementById!("preview-host").object else {
      fatalError("Failed to get preview host")
    }
    let rootEnvironment = EnvironmentValues()
    _ = preview.appendChild!(div)

    _launch(app, rootEnvironment, div)
  } 
}
