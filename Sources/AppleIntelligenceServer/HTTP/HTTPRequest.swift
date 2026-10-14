import Foundation

struct HTTPRequest: Equatable, Sendable {
    let method: String
    let path: String
    let body: Data
}

enum HTTPRequestParser {
    private static let headerTerminator = Data("\r\n\r\n".utf8)

    /// Returns the request once its head and whole declared body have arrived, or nil while bytes are still missing.
    static func parse(_ received: Data) -> HTTPRequest? {
        guard let terminator = received.range(of: headerTerminator),
              let head = String(data: received[received.startIndex..<terminator.lowerBound], encoding: .utf8)
        else { return nil }
        let lines = head.components(separatedBy: "\r\n")
        let requestLine = lines[0].split(separator: " ")
        guard requestLine.count >= 2 else { return nil }

        let bodyLength = contentLength(in: lines.dropFirst())
        let body = received[terminator.upperBound...]
        guard body.count >= bodyLength else { return nil }
        return HTTPRequest(
            method: String(requestLine[0]),
            path: pathWithoutQuery(String(requestLine[1])),
            body: Data(body.prefix(bodyLength))
        )
    }

    private static func contentLength(in headerLines: ArraySlice<String>) -> Int {
        for line in headerLines {
            let field = line.split(separator: ":", maxSplits: 1)
            guard field.count == 2, field[0].trimmingCharacters(in: .whitespaces).lowercased() == "content-length" else { continue }
            return Int(field[1].trimmingCharacters(in: .whitespaces)) ?? 0
        }
        return 0
    }

    private static func pathWithoutQuery(_ target: String) -> String {
        String(target.prefix { $0 != "?" })
    }
}
