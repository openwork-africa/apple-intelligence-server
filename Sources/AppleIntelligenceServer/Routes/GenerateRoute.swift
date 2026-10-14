struct GenerateRoute: RouteHandler {
    struct Prompt: Decodable {
        let prompt: String
        let instructions: String?
        let temperature: Double?
    }

    struct Answer: Encodable {
        let ok: Bool
        var output: String?
        var error: String?
    }

    func reply(to request: HTTPRequest) async -> RouteReply {
        guard let prompt = JSON.decode(Prompt.self, from: request.body) else {
            return .complete(.json(Answer(ok: false, error: "the body must be JSON with a \"prompt\" string"), status: .badRequest))
        }
        do {
            let output = try await TextGenerator().generate(prompt: prompt.prompt, instructions: prompt.instructions, temperature: prompt.temperature)
            return .complete(.json(Answer(ok: true, output: output)))
        } catch {
            let failure = GenerationFailure.describing(error)
            return .complete(.json(Answer(ok: false, error: failure.message), status: failure.status))
        }
    }
}
