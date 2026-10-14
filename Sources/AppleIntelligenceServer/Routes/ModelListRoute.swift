struct ModelListRoute: RouteHandler {
    func reply(to request: HTTPRequest) async -> RouteReply {
        .complete(.json(ModelList(data: [ModelList.Entry(id: ServerInfo.modelIdentifier)])))
    }
}
