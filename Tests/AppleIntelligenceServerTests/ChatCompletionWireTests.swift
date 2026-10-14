import Foundation
import Testing
@testable import AppleIntelligenceServer

@Suite struct ChatCompletionWireTests {
    private func request(_ json: String) -> ChatCompletionRequest? {
        JSON.decode(ChatCompletionRequest.self, from: Data(json.utf8))
    }

    @Test func readsSnakeCaseFieldsAndToolNames() {
        let decoded = request(#"{"messages":[{"role":"user","content":"hi"}],"max_tokens":20,"tools":[{"type":"function","function":{"name":"Read","parameters":{}}}]}"#)
        #expect(decoded?.maxTokens == 20)
        #expect(decoded?.requestedToolNames == ["Read"])
        #expect(decoded?.modelIdentifier == ServerInfo.modelIdentifier)
    }

    @Test func joinsTheTextPartsOfListContent() {
        let decoded = request(#"{"messages":[{"role":"user","content":[{"type":"text","text":"Hello, "},{"type":"image_url"},{"type":"text","text":"world"}]}]}"#)
        #expect(decoded?.messages.first?.content == "Hello, world")
    }

    @Test func readsAToolResultAndTheCallItAnswers() {
        let decoded = request(#"{"messages":[{"role":"assistant","content":null,"tool_calls":[{"id":"call_1","type":"function","function":{"name":"Read","arguments":"{}"}}]},{"role":"tool","tool_call_id":"call_1","content":"done"}]}"#)
        #expect(decoded?.messages.first?.toolCalls?.first?.function.name == "Read")
        #expect(decoded?.messages.last?.toolCallId == "call_1")
    }

    @Test func refusesABodyWithoutMessages() {
        #expect(request(#"{"prompt":"hi"}"#) == nil)
    }

    @Test func aToolCallAnswerSaysSoInItsFinishReason() {
        let call = ChatToolCall(id: "call_1", function: ChatFunctionCall(name: "Read", arguments: "{}"))
        let response = ChatCompletionResponse(model: "apple-intelligence", outcome: .toolCalls([call]))
        let encoded = String(decoding: JSON.encode(response), as: UTF8.self)
        #expect(encoded.contains(#""finish_reason":"tool_calls""#))
        #expect(encoded.contains(#""tool_calls":[{"function":{"arguments":"{}","name":"Read"},"id":"call_1","type":"function"}]"#))
    }

    @Test func anEventIsOneDataFrame() {
        let frame = String(decoding: ServerSentEvent.frame(["answer": "yes"]), as: UTF8.self)
        #expect(frame == "data: {\"answer\":\"yes\"}\n\n")
    }
}
