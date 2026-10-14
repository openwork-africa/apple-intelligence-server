import Foundation
import Testing
@testable import AppleIntelligenceServer

@Suite struct RouterTests {
    private func response(_ reply: RouteReply) -> HTTPResponse? {
        if case .complete(let response) = reply { response } else { nil }
    }

    @Test func answersAnUnknownRouteWithNotFound() async {
        let reply = await Router.standard.reply(to: HTTPRequest(method: "GET", path: "/nowhere", body: Data()))
        #expect(response(reply)?.status == .notFound)
    }

    @Test func listsTheOneModel() async {
        let reply = await Router.standard.reply(to: HTTPRequest(method: "GET", path: "/v1/models", body: Data()))
        let body = String(decoding: response(reply)?.body ?? Data(), as: UTF8.self)
        #expect(body.contains(#""id":"apple-intelligence""#))
    }

    @Test func refusesAChatBodyThatIsNotJSON() async {
        let reply = await Router.standard.reply(to: HTTPRequest(method: "POST", path: "/v1/chat/completions", body: Data("nope".utf8)))
        #expect(response(reply)?.status == .badRequest)
    }

    @Test func offersEveryToolByItsName() {
        #expect(ToolCatalog.names == ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "WebFetch", "WebSearch", "TodoWrite", "NotebookEdit"])
        #expect(ToolCatalog.tool(named: "Read") != nil)
        #expect(ToolCatalog.tool(named: "Unknown") == nil)
    }
}
