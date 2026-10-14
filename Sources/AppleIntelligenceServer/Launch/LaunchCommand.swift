enum LaunchFailure: Error, Equatable {
    case invalidPort(String)
    case missingValue(option: String)
    case unknownArgument(String)
    case cannotListen(port: UInt16, reason: String)

    var message: String {
        switch self {
        case .invalidPort(let given): "\"\(given)\" is not a port: give a number from 1 to 65535."
        case .missingValue(let option): "\(option) needs a value."
        case .unknownArgument(let argument): "\"\(argument)\" is not understood. Run with --help to see what is."
        case .cannotListen(let port, let reason): "Could not listen on port \(port): \(reason)"
        }
    }
}

enum LaunchCommand: Equatable {
    case serve(port: UInt16)
    case ask(prompt: String?, instructions: String?)
    case showVersion
    case showHelp

    static let help = """
    \(ServerInfo.name) \(ServerInfo.version)
    Apple's on-device model behind an OpenAI-compatible API.

    USAGE
      \(ServerInfo.name) [serve] [--port <number>]    Serve the API on 127.0.0.1 (port \(ServerInfo.defaultPort) by default)
      \(ServerInfo.name) ask [<prompt>] [--instructions <text>]
                                                       Answer one prompt and print it; the prompt is read
                                                       from standard input when it is not given
      \(ServerInfo.name) --version
      \(ServerInfo.name) --help
    """

    /// Reads the command line, without the program's own name.
    static func parse(_ arguments: [String]) throws -> LaunchCommand {
        var remaining = arguments[...]
        switch remaining.first {
        case "--help", "-h": return .showHelp
        case "--version", "-v": return .showVersion
        case "ask":
            remaining.removeFirst()
            return try parseAsk(remaining)
        case "serve":
            remaining.removeFirst()
            return try parseServe(remaining)
        default:
            return try parseServe(remaining)
        }
    }

    private static func parseServe(_ arguments: ArraySlice<String>) throws -> LaunchCommand {
        var port = ServerInfo.defaultPort
        var remaining = arguments
        while let argument = remaining.popFirst() {
            guard argument == "--port" else { throw LaunchFailure.unknownArgument(argument) }
            guard let given = remaining.popFirst() else { throw LaunchFailure.missingValue(option: argument) }
            guard let parsed = UInt16(given), parsed > 0 else { throw LaunchFailure.invalidPort(given) }
            port = parsed
        }
        return .serve(port: port)
    }

    private static func parseAsk(_ arguments: ArraySlice<String>) throws -> LaunchCommand {
        var prompt: String?
        var instructions: String?
        var remaining = arguments
        while let argument = remaining.popFirst() {
            if argument == "--instructions" {
                guard let given = remaining.popFirst() else { throw LaunchFailure.missingValue(option: argument) }
                instructions = given
            } else if prompt == nil {
                prompt = argument
            } else {
                throw LaunchFailure.unknownArgument(argument)
            }
        }
        return .ask(prompt: prompt, instructions: instructions)
    }
}
