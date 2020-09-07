import JavaScriptKit

struct DataBuffer {
    private let buffer: JSObjectRef

    init(arrayBuffer: JSObjectRef) {
        self.buffer = arrayBuffer
    }

    func slice(from begin: Int, to end: Int? = nil) -> DataBuffer {
        if let end = end {
            return DataBuffer(arrayBuffer: buffer.slice!(begin, end).object!)
        } else {
            return DataBuffer(arrayBuffer: buffer.slice!(begin).object!)
        }
    }

    var byteLength: Int { Int(buffer.byteLength.number!) }

    static let Uint8Array = JSObjectRef.global.Uint8Array.function!

    var uint8: [UInt8] {
        let uint8Buffer = Self.Uint8Array.new(buffer)
        var _buffer = [UInt8]()
        let count = Int(uint8Buffer.length.number!)
        _buffer.reserveCapacity(count)
        for index in 0..<count {
            _buffer.append(UInt8(uint8Buffer[index].number!))
        }
        return _buffer
    }
}
