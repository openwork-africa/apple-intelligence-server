import Foundation
import FoundationModels

struct ChatCompletionGenerator: Sendable {
    /// Answers the conversation with text, or with the tool calls the model wants the client to run.
    func complete(_ request: ChatCompletionRequest) async throws -> ChatCompletionOutcome {
        let chat = try prepare(request)
        do {
            let response = try await chat.session.respond(to: chat.prompt, options: options(for: request))
            return .text(response.content)
        } catch let error as LanguageModelSession.ToolCallError {
            guard let call = error.underlyingError as? ToolCallLeftToClient else { throw GenerationFailure.describing(error) }
            return .toolCalls([ChatToolCall(id: "call_\(UUID().uuidString)", function: ChatFunctionCall(name: call.toolName, arguments: call.argumentsJSON))])
        } catch {
            throw GenerationFailure.describing(error)
        }
    }

    /// Answers the conversation as pieces of text, in the order the model writes them.
    func streamText(_ request: ChatCompletionRequest) throws -> AsyncThrowingStream<String, any Error> {
        let chat = try prepare(request)
        let options = options(for: request)
        return AsyncThrowingStream { continuation in
            let streaming = Task {
                do {
                    var textSoFar = ""
                    for try await snapshot in chat.session.streamResponse(to: chat.prompt, options: options) where snapshot.content.count > textSoFar.count {
                        continuation.yield(String(snapshot.content.dropFirst(textSoFar.count)))
                        textSoFar = snapshot.content
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: GenerationFailure.describing(error))
                }
            }
            continuation.onTermination = { _ in streaming.cancel() }
        }
    }

    private func prepare(_ request: ChatCompletionRequest) throws -> PreparedChat {
        try LanguageModelAvailability.requireAvailable()
        let tools = request.requestedToolNames.compactMap(ToolCatalog.tool(named:))
        return try ChatTranscriptBuilder(messages: request.messages, tools: tools).prepare()
    }

    private func options(for request: ChatCompletionRequest) -> GenerationOptions {
        GenerationOptions(temperature: request.temperature, maximumResponseTokens: request.maxTokens)
    }
}
