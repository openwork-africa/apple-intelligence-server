import Foundation
import Testing
@testable import AppleIntelligenceServer

@Suite struct HTTPResponseTests {
    @Test func serializesStatusHeadersAndBody() {
        let response = HTTPResponse(status: .notFound, body: Data("{}".utf8))
        let expected = "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}"
        #expect(String(decoding: response.serialized, as: UTF8.self) == expected)
    }

    @Test func namesTheErrorTypeAfterWhoIsAtFault() {
        let clientError = String(decoding: HTTPResponse.openAIError("bad", status: .badRequest).body, as: UTF8.self)
        let serverError = String(decoding: HTTPResponse.openAIError("broke", status: .internalServerError).body, as: UTF8.self)
        #expect(clientError == #"{"error":{"message":"bad","type":"invalid_request_error"}}"#)
        #expect(serverError == #"{"error":{"message":"broke","type":"server_error"}}"#)
    }
}
