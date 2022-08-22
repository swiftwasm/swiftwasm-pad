import JavaScriptKit

public class Promise: ConvertibleToJSValue {
    let ref: JSObject
    public init?(_ value: JSValue) {
        guard let ref = value.object else {
            return nil
        }
        self.ref = ref
    }

    @discardableResult
    public func then(_ transform: @escaping (JSValue) -> JSValue) -> Promise {
        let result = ref.then!(JSValue.function({ args in
            transform(args[0])
        }))
        return Promise(result)!
    }

    @discardableResult
    public func `catch`(_ handler: @escaping (JSValue) -> Void) -> Promise {
        let result = ref.catch!(JSValue.function({ args in
            handler(args[0])
            return .undefined
        }))
        return Promise(result)!
    }

    @discardableResult
    public func finally(_ handler: @escaping () -> Void) -> Promise {
        let result = ref.finally!(JSValue.function({ _ in
            handler()
            return .undefined
        }))
        return Promise(result)!
    }

    public var jsValue: JSValue {
        return .object(ref)
    }
}

import OpenCombineShim

struct JSError: Error {
    let value: JSValue
    init(value: JSValue) {
        console.error(value)
        self.value = value
    }
}

func futurefy(_ promise: Promise) -> Future<JSValue, JSError> {
    Future { resolver in
        promise
            .catch { error in
                resolver(.failure(JSError(value: error)))
            }
            
            .then { value in
                resolver(.success(value))
                return .undefined
            }
    }
}
