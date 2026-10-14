import Foundation

public enum Launcher {
    private static let usageError: Int32 = 64

    /// Runs what the command line asks for and ends the process with its exit code.
    public static func run(arguments: [String]) async -> Never {
        do {
            switch try LaunchCommand.parse(arguments) {
            case .showHelp: print(LaunchCommand.help)
            case .showVersion: print(ServerInfo.version)
            case .serve(let port): try await HTTPServer(port: port, router: .standard).run()
            case .ask(let prompt, let instructions): try await answer(prompt ?? standardInput(), instructions: instructions)
            }
            exit(EXIT_SUCCESS)
        } catch let failure as LaunchFailure {
            Log.write(failure.message)
            exit(usageError)
        } catch {
            Log.write(GenerationFailure.describing(error).message)
            exit(EXIT_FAILURE)
        }
    }

    private static func answer(_ prompt: String, instructions: String?) async throws {
        print(try await TextGenerator().generate(prompt: prompt, instructions: instructions))
    }

    private static func standardInput() -> String {
        String(decoding: FileHandle.standardInput.readDataToEndOfFile(), as: UTF8.self)
    }
}
