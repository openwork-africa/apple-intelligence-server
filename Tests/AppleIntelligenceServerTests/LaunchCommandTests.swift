import Testing
@testable import AppleIntelligenceServer

@Suite struct LaunchCommandTests {
    @Test func servesOnTheDefaultPortWhenGivenNothing() throws {
        #expect(try LaunchCommand.parse([]) == .serve(port: ServerInfo.defaultPort))
    }

    @Test func servesOnTheGivenPort() throws {
        #expect(try LaunchCommand.parse(["serve", "--port", "9000"]) == .serve(port: 9000))
        #expect(try LaunchCommand.parse(["--port", "9000"]) == .serve(port: 9000))
    }

    @Test func refusesAPortThatIsNotOne() {
        #expect(throws: LaunchFailure.invalidPort("seventy")) { try LaunchCommand.parse(["--port", "seventy"]) }
        #expect(throws: LaunchFailure.invalidPort("0")) { try LaunchCommand.parse(["--port", "0"]) }
        #expect(throws: LaunchFailure.missingValue(option: "--port")) { try LaunchCommand.parse(["--port"]) }
    }

    @Test func asksWithAPromptAndInstructions() throws {
        #expect(try LaunchCommand.parse(["ask", "why?", "--instructions", "be brief"]) == .ask(prompt: "why?", instructions: "be brief"))
        #expect(try LaunchCommand.parse(["ask"]) == .ask(prompt: nil, instructions: nil))
    }

    @Test func refusesWhatItDoesNotUnderstand() {
        #expect(throws: LaunchFailure.unknownArgument("--loud")) { try LaunchCommand.parse(["serve", "--loud"]) }
        #expect(throws: LaunchFailure.unknownArgument("two")) { try LaunchCommand.parse(["ask", "one", "two"]) }
    }

    @Test func showsHelpAndVersion() throws {
        #expect(try LaunchCommand.parse(["--help"]) == .showHelp)
        #expect(try LaunchCommand.parse(["--version"]) == .showVersion)
    }
}
