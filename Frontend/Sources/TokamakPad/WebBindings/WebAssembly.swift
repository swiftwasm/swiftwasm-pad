import JavaScriptKit
import CombineShim

class WebAssembly {
    private static let Uint8Array = JSObjectRef.global.Uint8Array.function!
    private static let swiftExport = JSObjectRef.global.swiftExports.object!
    private static let execWasm = swiftExport.execWasm.function!

    static func runWasm(_ arrayBuffer: JSObjectRef) -> AnyPublisher<Void, Error> {
        let promise = Promise(execWasm(arrayBuffer))!
        return futurefy(promise).map { _ in }
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}
