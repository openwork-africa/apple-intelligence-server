import FoundationModels

enum ToolCatalog {
    static let tools: [any Tool] = [
        ClientTool<ReadArguments>(name: "Read", description: "Reads a file from the local filesystem."),
        ClientTool<WriteArguments>(name: "Write", description: "Writes a file to the local filesystem, replacing it if it exists."),
        ClientTool<EditArguments>(name: "Edit", description: "Replaces an exact piece of text in a file."),
        ClientTool<BashArguments>(name: "Bash", description: "Runs a shell command."),
        ClientTool<GlobArguments>(name: "Glob", description: "Finds files whose paths match a glob pattern."),
        ClientTool<GrepArguments>(name: "Grep", description: "Searches file contents with a regular expression."),
        ClientTool<WebFetchArguments>(name: "WebFetch", description: "Fetches a URL and extracts what the prompt asks for."),
        ClientTool<WebSearchArguments>(name: "WebSearch", description: "Searches the web and returns results."),
        ClientTool<TodoWriteArguments>(name: "TodoWrite", description: "Creates or updates the task checklist."),
        ClientTool<NotebookEditArguments>(name: "NotebookEdit", description: "Replaces, inserts or deletes a cell in a Jupyter notebook."),
    ]

    static var names: [String] { tools.map(\.name) }

    /// The tool a client asks for by name, or nil: the model only accepts argument shapes known at compile time, so a client cannot bring its own.
    static func tool(named name: String) -> (any Tool)? {
        tools.first { $0.name == name }
    }
}
