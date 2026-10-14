struct HealthRoute: RouteHandler {
    struct Health: Encodable {
        let ok = true
        let available: Bool
        let reason: String?
    }

    /// Answers 200 only when the model can generate, so the status alone says whether the server is ready.
    func reply(to request: HTTPRequest) async -> RouteReply {
        let availability = LanguageModelAvailability.current
        let health = Health(available: availability.isAvailable, reason: availability.unavailableReason)
        return .complete(.json(health, status: availability.isAvailable ? .ok : .serviceUnavailable))
    }
}
