import CombineShim
import JavaScriptKit

struct MessageError: Error {
    let message: String
    let line: UInt
    init(message: String, line: UInt = #line) {
        self.message = message
        self.line = line
    }
}

#if DEBUG
let endpoint = "http://dev-lambda.swiftwasm.org:8090/invoke"
#else
let endpoint = "https://syzf23805k.execute-api.ap-northeast-1.amazonaws.com/prod/CompileSwiftWasm"
#endif

class CompilerAPI {
    func compile(code: String) -> AnyPublisher<JSObjectRef, Error> {
        let body = JSON.stringify(["mainCode": code])
        let options: [String: JSValueConvertible] = [
            "mode": "cors",
            "method": "POST",
            "body": body,
            "headers": [
                "Content-Type": "application/json"
            ],
        ]
        let promise = fetch(endpoint, options: options)

        return futurefy(promise)
            .flatMap { response -> Future<JSValue, JSError> in
                let promise = response.object!.arrayBuffer!()
                return futurefy(Promise(promise)!)
            }
            .map { $0.object! }
            .mapError { error -> Error in
                console.log(error.value)
                return MessageError(message: error.value.object!.message.string!)
            }
            .eraseToAnyPublisher()
            
    }
    
    func sharedLibrary() -> AnyPublisher<JSObjectRef, Error> {
        let promise = fetch("library.so.wasm", options: [:])
        return futurefy(promise)
            .flatMap { response -> Future<JSValue, JSError> in
                let promise = response.object!.arrayBuffer!()
                return futurefy(Promise(promise)!)
            }
            .map { $0.object! }
            .mapError { error -> Error in
                console.log(error.value)
                return MessageError(message: error.value.object!.message.string!)
            }
            .eraseToAnyPublisher()
    }
}

