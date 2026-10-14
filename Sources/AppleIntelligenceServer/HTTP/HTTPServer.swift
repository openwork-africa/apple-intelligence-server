import Foundation
import Network

struct HTTPServer: Sendable {
    let port: UInt16
    let router: Router

    /// Serves on the loopback interface only, until listening fails: the model is served without authentication, so it must not be reachable from other machines.
    func run() async throws {
        guard let endpointPort = NWEndpoint.Port(rawValue: port) else { throw LaunchFailure.invalidPort(String(port)) }
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: endpointPort)
        let listener = try NWListener(using: parameters)
        let connectionQueue = DispatchQueue(label: "\(ServerInfo.name).connections")

        listener.newConnectionHandler = { accepted in
            accepted.start(queue: connectionQueue)
            Task { await serve(HTTPConnection(connection: accepted)) }
        }
        let failure: NWError = await withCheckedContinuation { continuation in
            listener.stateUpdateHandler = { state in
                switch state {
                case .ready: Log.write("listening on http://127.0.0.1:\(port) (\(LanguageModelAvailability.current.summary))")
                case .failed(let error): continuation.resume(returning: error)
                default: break
                }
            }
            listener.start(queue: connectionQueue)
        }
        throw LaunchFailure.cannotListen(port: port, reason: String(describing: failure))
    }

    private func serve(_ connection: HTTPConnection) async {
        defer { connection.close() }
        guard let request = await connection.receiveRequest() else { return }
        switch await router.reply(to: request) {
        case .complete(let response):
            await connection.send(response.serialized)
        case .eventStream(let frames):
            await connection.send(HTTPResponse.eventStreamHead)
            for await frame in frames { await connection.send(frame) }
        }
    }
}
