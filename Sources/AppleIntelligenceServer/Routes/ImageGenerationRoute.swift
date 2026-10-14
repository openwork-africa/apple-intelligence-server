struct ImageGenerationRoute: RouteHandler {
    func reply(to request: HTTPRequest) async -> RouteReply {
        guard let generation = JSON.decode(ImageGenerationRequest.self, from: request.body) else {
            return .complete(.openAIError("the body must be JSON with a \"prompt\" string", status: .badRequest))
        }
        do {
            let images = try await ImageGenerator().generate(prompt: generation.prompt, styleName: generation.style, count: generation.n)
            return .complete(.json(ImageGenerationResponse(base64Images: images)))
        } catch {
            return .complete(.openAIError(.describing(error)))
        }
    }
}
