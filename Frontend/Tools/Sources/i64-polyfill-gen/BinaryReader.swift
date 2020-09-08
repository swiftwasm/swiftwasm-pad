func decodeULEB128<T>(_ bytes: ArraySlice<UInt8>, _: T.Type) -> (value: T, offset: Int)
    where T: UnsignedInteger, T: FixedWidthInteger
{
    var index: Int = bytes.startIndex
    var value: T = 0
    var shift: UInt = 0
    var byte: UInt8
    repeat {
        byte = bytes[index]
        index += 1
        value |= T(byte & 0x7F) << shift
        shift += 7
    } while byte >= 128
    return (value, index - bytes.startIndex)
}

protocol BinaryReaderDelegate {
    func onImportFunc(
        _ importIndex: Index,
        _ module: String, _ field: String,
        _ funcIndex: Index,
        _ signatureIndex: Index
    )
    func onType(_ type: FuncType)
    func onFunctionName(_ index: Index, _ name: String)
}

final class BinaryReader {
    enum Error: Swift.Error {
        case invalidSectionCode(UInt8)
        case invalidValueType(UInt8)
    }

    class State {
        fileprivate(set) var offset: Offset = 0
        let bytes: [UInt8]

        init(bytes: [UInt8]) {
            self.bytes = bytes
        }
    }

    let length: Int
    let state: State
    var delegate: BinaryReaderDelegate

    var funcImportCount = 0
    var sectionEnd: Int!

    init(bytes: [UInt8], delegate: BinaryReaderDelegate) {
        length = bytes.count
        state = State(bytes: bytes)
        self.delegate = delegate
    }

    // MARK: - Reader Utilities

    @discardableResult
    func read(_ length: Int) -> ArraySlice<UInt8> {
        let result = state.bytes[state.offset ..< state.offset + length]
        state.offset += length
        return result
    }

    func readU8Fixed() -> UInt8 {
        let byte = state.bytes[state.offset]
        state.offset += 1
        return byte
    }

    func readU32Leb128() -> UInt32 {
        let (value, advanced) = decodeULEB128(state.bytes[state.offset...], UInt32.self)
        state.offset += advanced
        return value
    }

    func readString() -> String {
        let length = Int(readU32Leb128())
        let bytes = state.bytes[state.offset ..< state.offset + length]
        let name = String(decoding: bytes, as: Unicode.ASCII.self)
        state.offset += length
        return name
    }

    func readIndex() -> Index { Index(readU32Leb128()) }
    func readOffset() -> Offset { Offset(readU32Leb128()) }

    func consumeTable() throws {
        _ = readU8Fixed()
        let hasMax = readU8Fixed() != 0
        _ = Size(readU32Leb128())
        if hasMax { _ = readU32Leb128() }
    }

    func consumeMemory() {
        let flags = readU8Fixed()
        let hasMax = (flags & LIMITS_HAS_MAX_FLAG) != 0
        _ = Size(readU32Leb128())
        if hasMax { _ = readU32Leb128() }
    }

    func consumeGlobalHeader() throws {
        _ = try readValueType()
        _ = readU8Fixed()
    }

    func readValueType() throws -> ValueType {
        let rawType = readU8Fixed()
        guard let type = ValueType(rawValue: rawType) else {
            throw Error.invalidValueType(rawType)
        }
        return type
    }

    func readBytes() -> (data: ArraySlice<UInt8>, size: Size) {
        let size = Size(readU32Leb128())
        let data = state.bytes[state.offset ..< state.offset + size]
        state.offset += size
        return (data, size)
    }
    
    func readFuncType() throws -> FuncType {
        let header = readU8Fixed()
        assert(header == 0x60)
        return try FuncType(
            params: readResultType(),
            returns: readResultType()
        )
    }
    
    func readResultType() throws -> [ValueType] {
        let count = Int(readU32Leb128())
        var types = [ValueType]()
        for _ in 0 ..< count {
            try types.append(readValueType())
        }
        return types
    }

    // MARK: - Entry point

    func readModule() throws {
        let maybeMagic = read(4)
        assert(maybeMagic.elementsEqual(magic))
        let maybeVersion = read(4)
        assert(maybeVersion.elementsEqual(version))
        try readSections()
    }

    func readSections() throws {
        var isEOF: Bool { state.offset >= length }
        while !isEOF {
            let sectionCode = readU8Fixed()
            let size = Size(readU32Leb128())
            guard let section = BinarySection(rawValue: sectionCode) else {
                throw Error.invalidSectionCode(sectionCode)
            }
            sectionEnd = state.offset + size

            switch section {
            case .import:
                try readImportSection(sectionSize: size)
            case .type:
                try readTypeSection()
            case .custom:
                try readCustomSection(sectionSize: size)
            default:
                break
            }

            state.offset = sectionEnd
        }
    }
    
    func readTypeSection() throws {
        let count = Int(readU32Leb128())
        for _ in 0 ..< count {
            try delegate.onType(readFuncType())
        }
    }

    func readImportSection(sectionSize _: Size) throws {
        let importCount = Int(readU32Leb128())
        for importIdx in 0 ..< importCount {
            let module = readString()
            let field = readString()
            let rawKind = readU8Fixed()
            let kind = ExternalKind(rawValue: rawKind)
            switch kind {
            case .func:
                let signagureIdx = readIndex()
                delegate.onImportFunc(
                    importIdx,
                    module, field,
                    funcImportCount,
                    signagureIdx
                )
                funcImportCount += 1
            case .table:
                try consumeTable()
            case .memory:
                consumeMemory()
            case .global:
                try consumeGlobalHeader()
            default:
                if let kind = kind {
                    fatalError("Error: Import kind '\(kind)' is not supported")
                } else {
                    fatalError("Error: Import kind '(rawKind = \(rawKind))' is not supported")
                }
            }
        }
    }

    func readCustomSection(sectionSize: Size) throws {
        let sectionName = readString()
        // BeginCustomSection
        switch sectionName {
        case "name":
            try readNameSection(sectionSize: sectionSize)
        default:
            break
        }
    }
    
    func readNameSection(sectionSize: Size) throws {
        while state.offset < sectionEnd {
            let subsectionType = readU8Fixed()
            let subsectionSize = Size(readU32Leb128())
            let subsectionEnd = state.offset + subsectionSize

            switch NameSectionSubsection(rawValue: subsectionType) {
            case .function:
                let namesCount = readU32Leb128()
                for _ in 0 ..< namesCount {
                    let funcIdx = readIndex()
                    let funcName = readString()
                    delegate.onFunctionName(funcIdx, funcName)
                }
            default:
                // Skip
                state.offset = subsectionEnd
            }
        }
    }
}
