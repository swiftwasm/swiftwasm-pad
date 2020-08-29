import OpenCombine
import JavaScriptKit


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
        let promise = postFetch("http://dev-lambda.swiftwasm.org:8090/invoke", options: options)

        return futurefy(promise)
            .flatMap { response -> Future<JSValue, JSError> in
                let promise = response.object!.arrayBuffer!()
                return futurefy(Promise(promise)!)
            }
            .map { $0.object! }
            .mapError { error -> Error in
                MessageError(message: error.value.object!.message.string!)
            }
            .eraseToAnyPublisher()
            
    }
}

