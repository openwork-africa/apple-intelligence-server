import FoundationModels

@Generable
struct ReadArguments {
    @Guide(description: "Absolute path to the file to read")
    var file_path: String
    @Guide(description: "Line number to start reading from")
    var offset: Int?
    @Guide(description: "Number of lines to read")
    var limit: Int?
}

@Generable
struct WriteArguments {
    @Guide(description: "Absolute path to the file to write")
    var file_path: String
    @Guide(description: "The full content to write to the file")
    var content: String
}

@Generable
struct EditArguments {
    @Guide(description: "Absolute path to the file to edit")
    var file_path: String
    @Guide(description: "The exact text to replace")
    var old_string: String
    @Guide(description: "The text to replace it with")
    var new_string: String
    @Guide(description: "Replace every occurrence instead of just one")
    var replace_all: Bool?
}

@Generable
struct BashArguments {
    @Guide(description: "The shell command to execute")
    var command: String
    @Guide(description: "A short description of what the command does")
    var description: String?
    @Guide(description: "Timeout in milliseconds, up to 600000")
    var timeout: Int?
    @Guide(description: "Run the command in the background instead of waiting for it")
    var run_in_background: Bool?
}

@Generable
struct GlobArguments {
    @Guide(description: "The glob pattern to match files against, e.g. \"**/*.ts\"")
    var pattern: String
    @Guide(description: "Directory to search from; defaults to the current working directory")
    var path: String?
}

@Generable
enum GrepOutputMode {
    case content
    case files_with_matches
    case count
}

@Generable
struct GrepArguments {
    @Guide(description: "The regular expression pattern to search for")
    var pattern: String
    @Guide(description: "File or directory to search in; defaults to the current working directory")
    var path: String?
    @Guide(description: "What to return: matching lines, matching file paths, or match counts per file")
    var output_mode: GrepOutputMode?
    @Guide(description: "Glob to filter which files are searched, e.g. \"*.swift\"")
    var glob: String?
    @Guide(description: "File type to filter by, e.g. \"swift\", \"py\", \"js\"")
    var type: String?
    @Guide(description: "Ignore case when matching")
    var caseInsensitive: Bool?
    @Guide(description: "Show line numbers; only applies when output_mode is content")
    var lineNumbers: Bool?
    @Guide(description: "Lines of context after each match; only applies when output_mode is content")
    var contextAfter: Int?
    @Guide(description: "Lines of context before each match; only applies when output_mode is content")
    var contextBefore: Int?
    @Guide(description: "Lines of context before and after each match; only applies when output_mode is content")
    var contextAround: Int?
    @Guide(description: "Limit the number of results returned")
    var head_limit: Int?
}

@Generable
struct WebFetchArguments {
    @Guide(description: "The URL to fetch")
    var url: String
    @Guide(description: "What to extract from the fetched content")
    var prompt: String
}

@Generable
struct WebSearchArguments {
    @Guide(description: "The search query")
    var query: String
    @Guide(description: "Only include results from these domains")
    var allowed_domains: [String]?
    @Guide(description: "Never include results from these domains")
    var blocked_domains: [String]?
}

@Generable
enum TodoStatus {
    case pending
    case in_progress
    case completed
}

@Generable
struct TodoItem {
    @Guide(description: "The task, in the imperative form")
    var content: String
    @Guide(description: "Current status of this task")
    var status: TodoStatus
    @Guide(description: "The form shown while the task is under way, e.g. \"Running tests\"")
    var activeForm: String
}

@Generable
struct TodoWriteArguments {
    @Guide(description: "The full, up-to-date task list")
    var todos: [TodoItem]
}

@Generable
enum NotebookEditMode {
    case replace
    case insert
    case delete
}

@Generable
enum NotebookCellType {
    case code
    case markdown
}

@Generable
struct NotebookEditArguments {
    @Guide(description: "Absolute path to the .ipynb file")
    var notebook_path: String
    @Guide(description: "The new source for the cell")
    var new_source: String
    @Guide(description: "ID of the cell to edit; omit to target the first cell")
    var cell_id: String?
    @Guide(description: "Type of cell to insert; only used when edit_mode is insert")
    var cell_type: NotebookCellType?
    @Guide(description: "Whether to replace, insert or delete the cell")
    var edit_mode: NotebookEditMode?
}
