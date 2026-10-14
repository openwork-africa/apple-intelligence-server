import Foundation
import Testing
@testable import AppleIntelligenceServer

@Suite struct HTTPRequestParserTests {
    private func bytes(_ text: String) -> Data { Data(text.utf8) }

    @Test func parsesARequestWithItsBody() {
        let request = HTTPRequestParser.parse(bytes("POST /generate HTTP/1.1\r\nContent-Length: 5\r\n\r\nhello"))
        #expect(request == HTTPRequest(method: "POST", path: "/generate", body: bytes("hello")))
    }

    @Test func waitsForTheRestOfTheBody() {
        #expect(HTTPRequestParser.parse(bytes("POST /generate HTTP/1.1\r\nContent-Length: 5\r\n\r\nhel")) == nil)
    }

    @Test func waitsForTheEndOfTheHead() {
        #expect(HTTPRequestParser.parse(bytes("GET /health HTTP/1.1\r\nHost: localhost\r\n")) == nil)
    }

    @Test func readsTheLengthWhateverTheHeaderCase() {
        let request = HTTPRequestParser.parse(bytes("POST / HTTP/1.1\r\ncontent-length:2\r\n\r\nokextra"))
        #expect(request?.body == bytes("ok"))
    }

    @Test func leavesTheQueryOutOfThePath() {
        #expect(HTTPRequestParser.parse(bytes("GET /health?verbose=1 HTTP/1.1\r\n\r\n"))?.path == "/health")
    }
}
