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

struct CompileError: Error, Codable, CustomStringConvertible {
    let stderr: String
    let statusCode: Int32
    var description: String { stderr }
}

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
            .mapError { error -> Error in
                console.log(error.value)
                return MessageError(message: error.value.object!.message.string!)
            }
            .flatMap { response -> AnyPublisher<JSValue, Error> in
                let response = response.object!
                guard response.status.number! == 200 else {
                    let promise = response.json!()
                    return futurefy(Promise(promise)!)
                        .mapError { error -> Error in error }
                        .flatMap { (json: JSValue) -> Fail<JSValue, Error> in
                            let decoder = JSValueDecoder()
                            do {
                                let error: CompileError = try decoder.decode(from: json)
                                return Fail<JSValue, Error>(error: error)
                            } catch {
                                return Fail<JSValue, Error>(error: error)
                            }
                        }
                        .eraseToAnyPublisher()
                }
                let promise = response.arrayBuffer!()
                return futurefy(Promise(promise)!)
                    .mapError { error -> Error in
                        console.log(error.value)
                        return MessageError(message: error.value.object!.message.string!)
                    }
                    .eraseToAnyPublisher()
            }
            .map { $0.object! }
            .eraseToAnyPublisher()
            
    }
    
    func sharedLibrary() -> AnyPublisher<JSObjectRef, Error> {
        return futurefy(Promise(swiftExport.sharedLibrary)!)
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

