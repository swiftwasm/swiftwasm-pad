import Foundation

func exec(_ launchPath: String, _ arguments: [String]) {
    let process = Process()
    process.launchPath = launchPath
    process.arguments = arguments
    process.launch()
    process.waitUntilExit()
}

func makeTemporalyDirectory() -> URL {
    let tempdir = URL(fileURLWithPath: NSTemporaryDirectory())
    let templatePath = tempdir.appendingPathComponent("swiftwasm-pad.XXXXXX")
    var template = [UInt8](templatePath.path.utf8).map({ Int8($0) }) + [Int8(0)]
    if mkdtemp(&template) == nil {
        fatalError("Failed to create temp directory")
    }
    return URL(fileURLWithPath: String(cString: template))
}
