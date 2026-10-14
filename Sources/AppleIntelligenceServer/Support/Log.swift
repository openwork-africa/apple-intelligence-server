import Foundation

enum Log {
    /// Writes one line to standard error, so standard output stays free for answers.
    static func write(_ message: String) {
        FileHandle.standardError.write(Data("[\(ServerInfo.name)] \(message)\n".utf8))
    }
}
