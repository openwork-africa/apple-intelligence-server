import Foundation

enum ServerSentEvent {
    /// The frame that tells an OpenAI client the stream is over.
    static let done = Data("data: [DONE]\n\n".utf8)

    /// One `data:` frame carrying the encoded value.
    static func frame<Value: Encodable>(_ value: Value) -> Data {
        Data("data: ".utf8) + JSON.encode(value) + Data("\n\n".utf8)
    }
}
