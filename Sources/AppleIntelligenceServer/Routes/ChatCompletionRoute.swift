import Foundation

struct ChatCompletionRoute: RouteHandler {
    private let generator = ChatCompletionGenerator()

    /// Answers whole or as events. The model gives a tool call whole, not in pieces, so a streamed request that names tools is answered in one event.
    func reply(to request: HTTPRequest) async -> RouteReply {
        guard let completion = JSON.decode(ChatCompletionRequest.self, from: request.body) else {
            return .complete(.openAIError("the body must be JSON with a \"messages\" list", status: .badRequest))
        }
        do {
            guard completion.stream == true else {
                let outcome = try await generator.complete(completion)
                return .complete(.json(ChatCompletionResponse(model: completion.modelIdentifier, outcome: outcome)))
            }
            let events = ChatCompletionEvents(model: completion.modelIdentifier)
            if completion.requestedToolNames.isEmpty {
                return .eventStream(events.frames(forText: try generator.streamText(completion)))
            }
            return .eventStream(events.frames(for: try await generator.complete(completion)))
        } catch {
            return .complete(.openAIError(.describing(error)))
        }
    }
}

struct ChatCompletionEvents: Sendable {
    let id = "chatcmpl-\(UUID().uuidString)"
    let created = Int(Date().timeIntervalSince1970)
    let model: String

    /// A finished answer as a stream of one event.
    func frames(for outcome: ChatCompletionOutcome) -> AsyncStream<Data> {
        let message = outcome.message
        let delta = ChatCompletionChunk.Delta(role: .assistant, content: message.content, toolCalls: message.toolCalls)
        return AsyncStream { continuation in
            continuation.yield(frame(delta, finishReason: outcome.finishReason))
            continuation.yield(ServerSentEvent.done)
            continuation.finish()
        }
    }

    /// One event per piece of text, then the event that ends the answer. A failure part-way is sent as an error event.
    func frames(forText pieces: AsyncThrowingStream<String, any Error>) -> AsyncStream<Data> {
        AsyncStream { continuation in
            let forwarding = Task {
                continuation.yield(frame(.init(role: .assistant)))
                do {
                    for try await piece in pieces { continuation.yield(frame(.init(content: piece))) }
                    continuation.yield(frame(.init(), finishReason: "stop"))
                } catch {
                    let failure = GenerationFailure.describing(error)
                    continuation.yield(ServerSentEvent.frame(OpenAIError(message: failure.message, status: failure.status)))
                }
                continuation.yield(ServerSentEvent.done)
                continuation.finish()
            }
            continuation.onTermination = { _ in forwarding.cancel() }
        }
    }

    private func frame(_ delta: ChatCompletionChunk.Delta, finishReason: String? = nil) -> Data {
        let chunk = ChatCompletionChunk(id: id, created: created, model: model, choices: [.init(delta: delta, finishReason: finishReason)])
        return ServerSentEvent.frame(chunk)
    }
}
