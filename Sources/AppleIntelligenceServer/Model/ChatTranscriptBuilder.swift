import Foundation
import FoundationModels

struct PreparedChat: Sendable {
    let session: LanguageModelSession
    let prompt: String
}

struct ChatTranscriptBuilder {
    let messages: [ChatMessage]
    let tools: [any Tool]

    /// Turns OpenAI messages into a session that holds the earlier turns, and the prompt to answer. A conversation that ends on a tool result is answered from that result, so it is replayed too and the prompt is left empty.
    func prepare() throws -> PreparedChat {
        guard let lastMessage = messages.last else { throw GenerationFailure.noMessages }
        guard lastMessage.role == .user || lastMessage.role == .tool else { throw GenerationFailure.lastMessageNotAnswerable }

        let endsOnToolResult = lastMessage.role == .tool
        let replayed = (endsOnToolResult ? messages[...] : messages.dropLast()).filter { !$0.role.isInstruction }
        let toolNamesByCallId = toolNamesByCallId(in: replayed)
        let entries = [instructionsEntry] + replayed.compactMap { entry(for: $0, toolNamesByCallId: toolNamesByCallId) }
        let session = LanguageModelSession(tools: tools, transcript: Transcript(entries: entries))
        return PreparedChat(session: session, prompt: endsOnToolResult ? "" : lastMessage.content ?? "")
    }

    /// The instructions must name the same tools the session is given, or the model fails when it calls one.
    private var instructionsEntry: Transcript.Entry {
        let instructions = messages.filter(\.role.isInstruction).compactMap(\.content).joined(separator: "\n\n")
        return .instructions(Transcript.Instructions(
            segments: [textSegment(instructions)],
            toolDefinitions: tools.map { Transcript.ToolDefinition(tool: $0) }
        ))
    }

    private func entry(for message: ChatMessage, toolNamesByCallId: [String: String]) -> Transcript.Entry? {
        switch message.role {
        case .tool:
            let callId = message.toolCallId ?? UUID().uuidString
            return .toolOutput(Transcript.ToolOutput(id: callId, toolName: toolNamesByCallId[callId] ?? "", segments: [textSegment(message.content)]))
        case .assistant:
            guard let toolCalls = message.toolCalls else {
                return .response(Transcript.Response(assetIDs: [], segments: [textSegment(message.content)]))
            }
            let replayedCalls = toolCalls.compactMap(transcriptToolCall)
            return replayedCalls.isEmpty ? nil : .toolCalls(Transcript.ToolCalls(replayedCalls))
        case .user, .system, .developer:
            return .prompt(Transcript.Prompt(segments: [textSegment(message.content)]))
        }
    }

    private func transcriptToolCall(_ call: ChatToolCall) -> Transcript.ToolCall? {
        guard let arguments = try? GeneratedContent(json: call.function.arguments) else { return nil }
        return Transcript.ToolCall(id: call.id, toolName: call.function.name, arguments: arguments)
    }

    private func toolNamesByCallId(in turns: [ChatMessage]) -> [String: String] {
        let calls = turns.flatMap { $0.toolCalls ?? [] }
        return Dictionary(calls.map { ($0.id, $0.function.name) }, uniquingKeysWith: { first, _ in first })
    }

    private func textSegment(_ text: String?) -> Transcript.Segment {
        .text(Transcript.TextSegment(content: text ?? ""))
    }
}
