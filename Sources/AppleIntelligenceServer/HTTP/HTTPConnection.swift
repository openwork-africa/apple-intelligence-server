import Foundation
import Network

struct HTTPConnection: Sendable {
    private static let largestChunk = 1 << 20
    private static let largestRequest = 32 << 20

    let connection: NWConnection

    /// Reads until one whole request has arrived. Returns nil when the peer closes, fails or sends too much.
    func receiveRequest() async -> HTTPRequest? {
        var received = Data()
        while received.count <= HTTPConnection.largestRequest {
            guard let chunk = await receiveChunk() else { return nil }
            received.append(chunk)
            if let request = HTTPRequestParser.parse(received) { return request }
        }
        return nil
    }

    func send(_ data: Data) async {
        await withCheckedContinuation { continuation in
            connection.send(content: data, completion: .contentProcessed { _ in continuation.resume() })
        }
    }

    func close() {
        connection.cancel()
    }

    private func receiveChunk() async -> Data? {
        await withCheckedContinuation { continuation in
            connection.receive(minimumIncompleteLength: 1, maximumLength: HTTPConnection.largestChunk) { data, _, _, error in
                let chunk = error == nil ? data.flatMap { $0.isEmpty ? nil : $0 } : nil
                continuation.resume(returning: chunk)
            }
        }
    }
}
