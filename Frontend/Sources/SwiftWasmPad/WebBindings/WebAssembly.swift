import JavaScriptKit
import CombineShim

class WebAssembly {
    private static let Uint8Array = JSObjectRef.global.Uint8Array.function!
    private static let swiftExport = JSObjectRef.global.swiftExports.object!
    private static let execWasmFn = swiftExport.execWasm.function!
    private static let installHookFn = swiftExport.installHook.function!

    static func runWasm(_ arrayBuffer: JSObjectRef) -> AnyPublisher<Void, Error> {
        let promise = Promise(execWasmFn(arrayBuffer))!
        return futurefy(promise).map { _ in }
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    typealias HookFn = (UInt32, String) -> Void
    private static var intalledHook: JSClosure?

    static func installHook(hook: @escaping HookFn) {
        let closure = JSClosure { args -> JSValue in
            let fd = UInt32(args[0].number!)
            let buf = args[1].string!
            hook(fd, buf)
            return .undefined
        }
        intalledHook = closure
        installHookFn(closure)
    }
}
