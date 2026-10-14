import Foundation

struct OpenAIError: Encodable {
    struct Detail: Encodable {
        let message: String
        let type: String
    }

    let error: Detail

    init(message: String, status: HTTPStatus) {
        error = Detail(message: message, type: status.isClientError ? "invalid_request_error" : "server_error")
    }
}

extension HTTPResponse {
    /// An error in the shape OpenAI clients expect.
    static func openAIError(_ message: String, status: HTTPStatus) -> HTTPResponse {
        .json(OpenAIError(message: message, status: status), status: status)
    }

    static func openAIError(_ failure: GenerationFailure) -> HTTPResponse {
        openAIError(failure.message, status: failure.status)
    }
}
