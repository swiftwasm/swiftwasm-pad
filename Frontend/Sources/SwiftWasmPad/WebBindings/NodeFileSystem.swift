import JavaScriptKit

class NodeFileSystem {
    let object: JSObjectRef
    init(object: JSObjectRef) {
        self.object = object
    }
    
    func writeFileSync(_ filename: String, buffer: JSObjectRef) {
        _ = object.writeFileSync!(filename, buffer)
    }
    
    func readFileSync(_ filename: String) -> JSObjectRef {
        object.readFileSync!(filename).object!
    }
}
