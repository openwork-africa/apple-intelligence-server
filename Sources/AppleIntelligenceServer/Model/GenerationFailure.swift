enum GenerationFailure: Error, Equatable {
    case modelUnavailable(reason: String)
    case noMessages
    case lastMessageNotAnswerable
    case noImages
    case failed(String)

    var status: HTTPStatus {
        switch self {
        case .modelUnavailable: .serviceUnavailable
        case .noMessages, .lastMessageNotAnswerable: .badRequest
        case .noImages: .unprocessableEntity
        case .failed: .internalServerError
        }
    }

    var message: String {
        switch self {
        case .modelUnavailable(let reason): "Apple Intelligence is not available: \(reason)"
        case .noMessages: "messages must not be empty"
        case .lastMessageNotAnswerable: "the last message must have the role \"user\" or \"tool\""
        case .noImages: "no images were generated"
        case .failed(let description): description
        }
    }

    /// Any error as a failure, unchanged when it already is one.
    static func describing(_ error: any Error) -> GenerationFailure {
        error as? GenerationFailure ?? .failed(String(describing: error))
    }
}
