protocol BinaryReader {
    func beginSection(type: UInt8, offset: Int,
                      contentStart: Int, contentEnd: Int)
}

func decodeLEB128(_ bytes: ArraySlice<UInt8>) -> (value: UInt32, offset: Int) {
    var index: Int = bytes.startIndex
    var value: UInt32 = 0
    var shift: UInt = 0
    var byte: UInt8
    repeat {
        byte = bytes[index]
        index += 1
        value |= UInt32(byte & 0x7f) << shift
        shift += 7
    } while (byte >= 128)
    return (value, index - bytes.startIndex)
}

class InputStream {
    private(set) var offset: Int = 0
    let bytes: [UInt8]
    let length: Int
    var isEOF: Bool {
        offset >= length
    }
    
    init(bytes: [UInt8]) {
        self.bytes = bytes
        self.length = bytes.count
    }

    @discardableResult
    func read(_ length: Int) -> ArraySlice<UInt8> {
        let result = bytes[offset..<offset+length]
        offset += length
        return result
    }

    func readUInt8() -> UInt8 {
        let byte = read(1)
        return byte[byte.startIndex]
    }

    func readVarUInt32() -> UInt32 {
        let (value, advanced) = decodeLEB128(bytes[offset...])
        offset += advanced
        return value
    }

    func readUInt32() -> UInt32 {
        let bytes = read(4)
        return UInt32(bytes[bytes.startIndex + 0])
            + (UInt32(bytes[bytes.startIndex + 1]) << 8)
            + (UInt32(bytes[bytes.startIndex + 2]) << 16)
            + (UInt32(bytes[bytes.startIndex + 3]) << 24)
    }
}

let magic: [UInt8] = [0x00, 0x61, 0x73, 0x6d]
let version: [UInt8] = [0x01, 0x00, 0x00, 0x00]
let customSectionId = 0

extension BinaryReader {
    func read(_ input: InputStream) {
        let maybeMagic = input.read(4)
        assert(maybeMagic.elementsEqual(magic))
        let maybeVersion = input.read(4)
        assert(maybeVersion.elementsEqual(version))
        while !input.isEOF {
            readSection(input)
        }
    }
    
    func readSection(_ input: InputStream) {
        let offset = input.offset
        let type = input.readUInt8()
        let size = Int(input.readVarUInt32())
        let contentStart = input.offset

        beginSection(type: type, offset: offset,
                     contentStart: contentStart,
                     contentEnd: contentStart + size)
        input.read(size)
    }
}

struct DebugStrip: BinaryReader {
    let input: InputStream
    let writer: (ArraySlice<UInt8>) -> Void

    func beginSection(type: UInt8, offset: Int, contentStart: Int, contentEnd: Int) {
        if type == customSectionId {
            let name = customSectionName(contentStart: contentStart, contentEnd: contentEnd)
            if name.hasPrefix(".debug_") ||
                name.hasPrefix("reloc..debug_") ||
                name == "name" { return }
        }
        let slice = input.bytes[offset..<contentEnd]
        writer(slice)
    }

    func customSectionName(contentStart: Int, contentEnd: Int) -> String {
        let (nameLength, advanced) = decodeLEB128(input.bytes[contentStart...])
        let nameOffset = contentStart + advanced
        let bytes = input.bytes[nameOffset..<nameOffset + Int(nameLength)]
        let name = String(bytes: bytes, encoding: .utf8)
        return name!
    }

    func strip() {
        writer(magic[...])
        writer(version[...])
        read(input)
    }
}

import Foundation

let inputFile = URL(fileURLWithPath: CommandLine.arguments[1])
let outputFile = URL(fileURLWithPath: CommandLine.arguments[2])
let filePointer = fopen(CommandLine.arguments[2], "wb")
defer { fclose(filePointer) }

let strip = try DebugStrip(
    input: InputStream(bytes: Array(Data(contentsOf: inputFile))),
    writer: { chunk in
        chunk.withUnsafeBytes { bytesPtr in
            while true {
                let n = fwrite(bytesPtr.baseAddress, 1, bytesPtr.count, filePointer)
                if n < 0 {
                    if errno == EINTR { continue }
                    fatalError()
                } else if n != bytesPtr.count {
                    fatalError()
                }
                break
            }
        }
    }
)

strip.strip()
