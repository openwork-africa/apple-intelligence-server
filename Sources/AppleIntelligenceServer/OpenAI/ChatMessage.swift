import Foundation

enum ChatRole: String, Codable, Sendable {
    case system, developer, user, assistant, tool

    var isInstruction: Bool { self == .system || self == .developer }
}

struct ChatFunctionCall: Codable, Equatable, Sendable {
    let name: String
    let arguments: String
}

struct ChatToolCall: Codable, Equatable, Sendable {
    let id: String
    var type: String? = "function"
    let function: ChatFunctionCall
}

struct ChatMessage: Codable, Equatable, Sendable {
    let role: ChatRole
    let content: String?
    var toolCalls: [ChatToolCall]?
    var toolCallId: String?

    private enum CodingKeys: String, CodingKey {
        case role, content, toolCalls, toolCallId
    }

    private struct ContentPart: Decodable {
        let text: String?
    }

    init(role: ChatRole, content: String?, toolCalls: [ChatToolCall]? = nil, toolCallId: String? = nil) {
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.toolCallId = toolCallId
    }

    /// Accepts content as plain text or as a list of parts, of which the text ones are joined.
    init(from decoder: Decoder) throws {
        let fields = try decoder.container(keyedBy: CodingKeys.self)
        role = try fields.decode(ChatRole.self, forKey: .role)
        toolCalls = try fields.decodeIfPresent([ChatToolCall].self, forKey: .toolCalls)
        toolCallId = try fields.decodeIfPresent(String.self, forKey: .toolCallId)
        if let parts = try? fields.decodeIfPresent([ContentPart].self, forKey: .content) {
            content = parts.compactMap(\.text).joined()
        } else {
            content = try fields.decodeIfPresent(String.self, forKey: .content)
        }
    }
}
