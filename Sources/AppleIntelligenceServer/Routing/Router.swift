import Foundation

enum RouteReply: Sendable {
    case complete(HTTPResponse)
    case eventStream(AsyncStream<Data>)
}

protocol RouteHandler: Sendable {
    /// Answers one request; a handler never touches the connection itself.
    func reply(to request: HTTPRequest) async -> RouteReply
}

struct Route: Hashable, Sendable {
    let method: String
    let path: String

    static func get(_ path: String) -> Route { Route(method: "GET", path: path) }
    static func post(_ path: String) -> Route { Route(method: "POST", path: path) }
}

struct Router: Sendable {
    let handlers: [Route: any RouteHandler]

    /// Every route this server answers.
    static let standard = Router(handlers: [
        .get("/health"): HealthRoute(),
        .post("/generate"): GenerateRoute(),
        .get("/v1/models"): ModelListRoute(),
        .post("/v1/chat/completions"): ChatCompletionRoute(),
        .post("/v1/images/generations"): ImageGenerationRoute(),
    ])

    func reply(to request: HTTPRequest) async -> RouteReply {
        let route = Route(method: request.method, path: request.path)
        guard let handler = handlers[route] else {
            return .complete(.openAIError("no such route: \(route.method) \(route.path)", status: .notFound))
        }
        return await handler.reply(to: request)
    }
}
