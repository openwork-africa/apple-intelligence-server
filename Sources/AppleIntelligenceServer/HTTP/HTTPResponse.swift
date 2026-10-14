import Foundation

struct HTTPStatus: Equatable, Sendable {
    let code: Int
    let reason: String

    static let ok = HTTPStatus(code: 200, reason: "OK")
    static let badRequest = HTTPStatus(code: 400, reason: "Bad Request")
    static let notFound = HTTPStatus(code: 404, reason: "Not Found")
    static let unprocessableEntity = HTTPStatus(code: 422, reason: "Unprocessable Entity")
    static let internalServerError = HTTPStatus(code: 500, reason: "Internal Server Error")
    static let serviceUnavailable = HTTPStatus(code: 503, reason: "Service Unavailable")

    var isClientError: Bool { (400..<500).contains(code) }
}

struct HTTPResponse: Equatable, Sendable {
    let status: HTTPStatus
    let body: Data

    /// A JSON response carrying the encoded value.
    static func json<Value: Encodable>(_ value: Value, status: HTTPStatus = .ok) -> HTTPResponse {
        HTTPResponse(status: status, body: JSON.encode(value))
    }

    /// The bytes sent over the wire: status line, headers and body.
    var serialized: Data {
        let head = HTTPResponse.head(status: status, headers: [
            "Content-Type: application/json",
            "Content-Length: \(body.count)",
        ])
        return head + body
    }

    /// The head that opens a server-sent event stream, which ends when the connection closes.
    static let eventStreamHead = head(status: .ok, headers: ["Content-Type: text/event-stream", "Cache-Control: no-cache"])

    private static func head(status: HTTPStatus, headers: [String]) -> Data {
        let lines = ["HTTP/1.1 \(status.code) \(status.reason)"] + headers + ["Connection: close", "", ""]
        return Data(lines.joined(separator: "\r\n").utf8)
    }
}
