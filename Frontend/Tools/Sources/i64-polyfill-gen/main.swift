import Foundation

extension String {
    func indent(_ width: Int) -> String {
        let space = String(repeating: " ", count: width)
        return self.split(separator: "\n").map { space + $0 }.joined(separator: "\n")
    }
}

struct FunctionImport {
    let type: FuncType
    let module: String
    let field: String
    var declName: String!
}

class Collector: BinaryReaderDelegate {
    private var types: [FuncType] = []
    private(set) var funcImports: [FunctionImport] = []

    func onType(_ type: FuncType) {
        types.append(type)
    }

    func onImportFunc(_ importIndex: Index, _ module: String, _ field: String, _ funcIndex: Index, _ signatureIndex: Index) {
        assert(signatureIndex < types.count)
        let funcImport = FunctionImport(type: types[signatureIndex], module: module, field: field)
        funcImports.append(funcImport)
    }
    func onFunctionName(_ index: Index, _ name: String) {
        guard index < funcImports.count else { return }
        funcImports[index].declName = name
    }
}


let inputFile = URL(fileURLWithPath: CommandLine.arguments[1])
let cOutputFile = URL(fileURLWithPath: CommandLine.arguments[2])
let jsOutputFile = URL(fileURLWithPath: CommandLine.arguments[3])

let bytes = try Array(Data(contentsOf: inputFile))
let collector = Collector()
let reader = BinaryReader(bytes: bytes, delegate: collector)
try reader.readModule()
let targetImports = collector.funcImports.filter {
    $0.type.params.contains(.i64)
}
let moduleName = "i64_polyfill"

func translateCType(from type: ValueType) -> String {
    switch type {
    case .i32: return "uint32_t"
    case .i64: return "uint64_t"
    case .f32: return "float"
    case .f64: return "double"
    }
}

func encodeCType(from type: ValueType) -> [String] {
    switch type {
    case .i32: return ["uint32_t"]
    case .i64: return ["uint32_t", "uint32_t"]
    case .f32: return ["float"]
    case .f64: return ["double"]
    }
}

func polyfillCCode(for funcImport: FunctionImport) -> String {
    assert(funcImport.type.returns.count <= 1)
    let cRetTy: String
    if let retTy = funcImport.type.returns.first {
        assert(retTy == .i32, "i64 result is not supported yet")
        cRetTy = translateCType(from: retTy)
    } else {
        cRetTy = "void"
    }

    let prototype: String
    let polyfillFn: String
    let loweredFunc = "\(moduleName)_\(funcImport.declName!)"
    do {
        let attr = """
        __attribute__((
            __import_module__("\(moduleName)"),
            __import_name__("\(funcImport.field)"),
        ))
        """
        prototype = """
        \(cRetTy) \(loweredFunc)(
            \(funcImport.type.params.flatMap(encodeCType)
                .enumerated().map { "\($0.element) arg\($0.offset)" }
                .joined(separator: ",\n    "))
        ) \(attr);
        """
    }
    
    do {
        var params: [(name: String, type: String)] = []
        var callArgs: [String] = []
        var encodeBody = ""
        for (index, param) in funcImport.type.params.enumerated() {
            let argName = "arg\(index)"
            params.append((argName, translateCType(from: param)))
            guard param == .i64 else {
                callArgs.append(argName)
                continue
            }
            let headArg = "\(argName)_head"
            let tailArg = "\(argName)_tail"
            encodeBody += """
            uint32_t \(headArg) = (\(argName) & 0xffff0000) >> 4;
            uint32_t \(tailArg) = (\(argName) & 0x0000ffff);
            """
            callArgs.append(contentsOf: [headArg, tailArg])
        }
        
        polyfillFn = """
        \(cRetTy) \(funcImport.declName!)(
            \(params.map { "\($0.type) \($0.name)" }.joined(separator: ",\n    "))
        ) {
        \(encodeBody.indent(4))
            return \(loweredFunc)(\(callArgs.joined(separator: ", ")));
        }
        """
    }
    
    return """
    \(prototype)
    \(polyfillFn)
    """
}

func polyfillJSFn(for funcImport: FunctionImport) -> String {
    var params: [String] = []
    var callArgs: [String] = []
    for (index, param) in funcImport.type.params.enumerated() {
        let argName = "arg\(index)"
        guard param == .i64 else {
            callArgs.append(argName)
            params.append(argName)
            continue
        }
        let headArg = "\(argName)_head"
        let tailArg = "\(argName)_tail"
        params.append(contentsOf: [headArg, tailArg])
        callArgs.append("(\(headArg) << 4) + \(tailArg)")
    }
    return """
    \(funcImport.field): (\(params.joined(separator: ", "))) => {
        return original.\(funcImport.field)(\(callArgs.joined(separator: ", ")));
    }
    """
}

let cCode = "#include <stdint.h>\n\n" +
    targetImports.map(polyfillCCode).joined(separator: "\n\n")

let jsCode = """
export function wrapI64Polyfill(original) {
    return {
\(targetImports.map(polyfillJSFn).map { $0.indent(8) }.joined(separator: ",\n"))
    };
}
"""

try cCode.write(to: cOutputFile, atomically: true, encoding: .utf8)
try jsCode.write(to: jsOutputFile, atomically: true, encoding: .utf8)
