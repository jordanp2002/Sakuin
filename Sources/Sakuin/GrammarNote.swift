import Foundation

struct GrammarNote: Identifiable, Hashable, Sendable {
    let url: URL
    let title: String
    let markdown: String
    let headings: [String]
    let aliases: [String]
    let searchTitle: String
    let searchAliases: [String]
    let searchHeadings: [String]
    let searchBody: String

    var id: URL { url }

    init(url: URL, markdown: String) {
        self.url = url
        self.markdown = markdown

        let parsedHeadings = markdown
            .split(separator: "\n")
            .compactMap { line -> String? in
                let text = line.trimmingCharacters(in: .whitespaces)
                guard text.hasPrefix("#") else { return nil }
                return text.drop(while: { $0 == "#" || $0 == " " }).nilIfEmpty
            }

        let fileTitle = url.deletingPathExtension().lastPathComponent
        self.title = fileTitle
        self.headings = parsedHeadings
        self.aliases = Self.makeAliases(from: self.title)
        searchTitle = GrammarSearch.normalize(fileTitle)
        searchAliases = aliases.map(GrammarSearch.normalize)
        searchHeadings = parsedHeadings.map(GrammarSearch.normalize)
        searchBody = GrammarSearch.normalize(markdown)

    }

    private static func makeAliases(from title: String) -> [String] {
        let separators = CharacterSet(charactersIn: "・／/")
        var values = title.components(separatedBy: separators)
        values.append(contentsOf: title.matches(of: /[（(]([^）)]+)[）)]/).map { String($0.1) })
        return values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != title }
    }
}

private extension Substring {
    var nilIfEmpty: String? {
        isEmpty ? nil : String(self)
    }
}
