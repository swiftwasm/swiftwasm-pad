import JavaScriptKit
import CombineShim

class WebAssembly {
    private static let Uint8Array = JSObjectRef.global.Uint8Array.function!

    static func runWasm(_ arrayBuffer: JSObjectRef) -> AnyPublisher<Void, Never> {
        let promise = swiftExport.execWasm!(arrayBuffer).object!
        return Future<Void, Never> { resolver in
            _ = promise.finally!(JSClosure { _ in
                resolver(.success(()))
                return .undefined
            })
            return
        }
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
        _ = swiftExport.installHook!(closure)
    }
}
