import JavaScriptKit
import OpenCombineShim

class Linker {
    private let worker = swiftExport.linkerWorker.object!
    private var listener: (Result<JSObject, Error>) -> Void = { _ in }

    init() {
        worker.onmessage = .function(JSClosure { [weak self] arguments in
            let buffer = arguments[0]
            self?.listener(.success(buffer.object!))
            return .undefined
        })
        worker.onmessageerror = .function(JSClosure { [weak self] arguments in
            let error = arguments[0]
            self?.listener(.failure(JSError(value: error)))
            return .undefined
        })
    }
    
    func writeInput(_ filename: String, buffer: JSObject) {
        let value: [String: ConvertibleToJSValue] = [
                "filename": filename,
                "buffer": buffer,
        ]
        let param: [String: ConvertibleToJSValue] = [
            "eventType": "writeInput",
            "value": value.jsValue,
        ]
        _ = worker.postMessage!(param.jsValue, [buffer])
    }

    func link(_ filenames: [String]) -> Future<JSObject, Error> {
        return Future { [weak self] resolver in
            self?.listener = { event in
                resolver(event.map { $0.data.object! })
            }
            _ = self?.worker.postMessage!(
                [
                    "eventType": "link",
                    "value": filenames.jsValue(),
                ]
            )
        }
    }
}


// This linkerMain is invoked in web worker

import ChibiLink
#if canImport(Darwin)
import Darwin
#else
import WASILibc
let SEEK_SET: Int32 = 0
let ENOENT: Int32 = 2
let EACCES: Int32 = 13
let ENOTDIR: Int32 = 20
let EISDIR: Int32 = 21
#endif

#if Xcode
func writeOutput(_: UnsafePointer<UInt8>, _ length: Int) { fatalError() }
#else
@_silgen_name("writeOutput")
func writeOutput(_: UnsafePointer<UInt8>, _ length: Int)
#endif

func linkerMain() throws {
    let exports = [
        "swjs_call_host_function",
        "swjs_prepare_host_function_call",
        "swjs_cleanup_host_function_call",
        "swjs_library_version",
    ]
    class OutputWriter: OutputByteStream {
        private(set) var bytes: [UInt8] = []
        private(set) var currentOffset: Int = 0

        func write(_ bytes: [UInt8], at offset: Int) throws {
            for index in offset ..< (offset + bytes.count) {
                self.bytes[index] = bytes[index - offset]
            }
        }

        func write(_ bytes: ArraySlice<UInt8>) throws {
            self.bytes.append(contentsOf: bytes)
            currentOffset += bytes.count
        }

        func writeString(_ value: String) throws {
            bytes.append(contentsOf: value.utf8)
            currentOffset += value.utf8.count
        }
    }
    let writer = OutputWriter()
    try performLinker(CommandLine.arguments, outputStream: writer, exports: exports)
    writer.bytes.withUnsafeBufferPointer { bufferPtr in
        writeOutput(bufferPtr.baseAddress!, bufferPtr.count)
    }
}
