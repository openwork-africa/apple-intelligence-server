import FoundationModels

struct ToolCallLeftToClient: Error {
    let toolName: String
    let argumentsJSON: String
}

struct ClientTool<Arguments: Generable>: Tool {
    let name: String
    let description: String

    /// Never produces output: it stops generation by throwing the call, which the client runs and answers.
    func call(arguments: Arguments) async throws -> String {
        throw ToolCallLeftToClient(toolName: name, argumentsJSON: arguments.generatedContent.jsonString)
    }
}
