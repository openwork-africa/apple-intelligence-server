import Foundation

struct ChatToolDefinition: Decodable, Sendable {
    struct Function: Decodable, Sendable {
        let name: String
    }

    let function: Function
}

struct ChatCompletionRequest: Decodable, Sendable {
    let model: String?
    let messages: [ChatMessage]
    let stream: Bool?
    let temperature: Double?
    let maxTokens: Int?
    let tools: [ChatToolDefinition]?

    var requestedToolNames: [String] { (tools ?? []).map(\.function.name) }
    var modelIdentifier: String { model ?? ServerInfo.modelIdentifier }
}

enum ChatCompletionOutcome: Equatable, Sendable {
    case text(String)
    case toolCalls([ChatToolCall])

    var finishReason: String {
        switch self {
        case .text: "stop"
        case .toolCalls: "tool_calls"
        }
    }

    var message: ChatMessage {
        switch self {
        case .text(let text): ChatMessage(role: .assistant, content: text)
        case .toolCalls(let calls): ChatMessage(role: .assistant, content: nil, toolCalls: calls)
        }
    }
}

struct ChatCompletionResponse: Encodable {
    struct Choice: Encodable {
        let index = 0
        let message: ChatMessage
        let finishReason: String
    }

    struct Usage: Encodable {
        let promptTokens = 0
        let completionTokens = 0
        let totalTokens = 0
    }

    let id = "chatcmpl-\(UUID().uuidString)"
    let object = "chat.completion"
    let created = Int(Date().timeIntervalSince1970)
    let model: String
    let choices: [Choice]
    let usage = Usage()

    init(model: String, outcome: ChatCompletionOutcome) {
        self.model = model
        choices = [Choice(message: outcome.message, finishReason: outcome.finishReason)]
    }
}

struct ChatCompletionChunk: Encodable {
    struct Delta: Encodable {
        var role: ChatRole?
        var content: String?
        var toolCalls: [ChatToolCall]?
    }

    struct Choice: Encodable {
        let index = 0
        let delta: Delta
        let finishReason: String?
    }

    let id: String
    let object = "chat.completion.chunk"
    let created: Int
    let model: String
    let choices: [Choice]
}
