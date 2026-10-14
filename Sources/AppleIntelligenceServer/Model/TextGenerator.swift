import FoundationModels

struct TextGenerator: Sendable {
    /// Answers one prompt with no history.
    func generate(prompt: String, instructions: String? = nil, temperature: Double? = nil) async throws -> String {
        try LanguageModelAvailability.requireAvailable()
        let session = instructions.map { LanguageModelSession(instructions: $0) } ?? LanguageModelSession()
        do {
            return try await session.respond(to: prompt, options: GenerationOptions(temperature: temperature)).content
        } catch {
            throw GenerationFailure.describing(error)
        }
    }
}
