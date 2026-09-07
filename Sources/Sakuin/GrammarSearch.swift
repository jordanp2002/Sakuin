import Foundation

enum MatchKind: String, Sendable {
    case title = "Title"
    case heading = "Heading"
    case body = "Note text"
}

struct SearchResult: Identifiable, Hashable, Sendable {
    let note: GrammarNote
    let score: Int
    let matchKind: MatchKind
    let excerpt: String?

    var id: GrammarNote.ID { note.id }
}

enum GrammarSearch {
    static func search(_ query: String, in notes: [GrammarNote]) -> [SearchResult] {
        let needle = normalize(query)
        guard !needle.isEmpty else { return [] }

        return notes.compactMap { note in
            result(for: note, needle: needle)
        }
        .sorted {
            if $0.score != $1.score { return $0.score > $1.score }
            let order = $0.note.title.localizedStandardCompare($1.note.title)
            return order == .orderedSame ? $0.note.url.path < $1.note.url.path : order == .orderedAscending
        }
    }

    private static func result(for note: GrammarNote, needle: String) -> SearchResult? {
        let title = note.searchTitle
        let aliases = note.searchAliases

        if title == needle {
            return SearchResult(note: note, score: 1_000, matchKind: .title, excerpt: nil)
        }
        if aliases.contains(needle) {
            return SearchResult(note: note, score: 950, matchKind: .title, excerpt: nil)
        }
        if title.hasPrefix(needle) || aliases.contains(where: { $0.hasPrefix(needle) }) {
            return SearchResult(note: note, score: 800, matchKind: .title, excerpt: nil)
        }
        if title.contains(needle) || aliases.contains(where: { $0.contains(needle) }) {
            return SearchResult(note: note, score: 650, matchKind: .title, excerpt: nil)
        }
        if let index = note.searchHeadings.firstIndex(where: { $0.contains(needle) }) {
            return SearchResult(note: note, score: 420, matchKind: .heading, excerpt: note.headings[index])
        }
        if note.searchBody.contains(needle) {
            return SearchResult(
                note: note,
                score: 200,
                matchKind: .body,
                excerpt: excerpt(in: note.markdown, matching: needle)
            )
        }
        return nil
    }

    static func normalize(_ value: String) -> String {
        value
            .precomposedStringWithCompatibilityMapping
            .lowercased()
            .filter { !$0.isWhitespace && !"~〜～・／/()（）".contains($0) }
    }

    private static func excerpt(in markdown: String, matching query: String) -> String? {
        let lines = markdown.split(separator: "\n").map(String.init)
        let normalizedQuery = normalize(query)
        guard let line = lines.first(where: { normalize($0).contains(normalizedQuery) }) else { return nil }
        return cleanMarkdown(line).truncated(to: 120)
    }

    private static func cleanMarkdown(_ value: String) -> String {
        MarkdownText.resolvingWikiLinks(value)
            .replacingOccurrences(of: #"^#{1,6}\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "**", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension String {
    func truncated(to limit: Int) -> String {
        count <= limit ? self : String(prefix(limit - 1)) + "…"
    }
}
