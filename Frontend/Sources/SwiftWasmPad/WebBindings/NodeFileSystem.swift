import JavaScriptKit

class NodeFileSystem {
    let object: JSObject
    init(object: JSObject) {
        self.object = object
    }
    
    func writeFileSync(_ filename: String, buffer: JSObject) {
        _ = object.writeFileSync!(filename, buffer)
    }
    
    func readFileSync(_ filename: String) -> JSObject {
        object.readFileSync!(filename).object!
    }
}
