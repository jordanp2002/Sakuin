import Foundation

enum MarkdownText {
    static func resolvingWikiLinks(_ source: String) -> String {
        source.replacingOccurrences(
            of: #"\[\[[^\]|]+\|([^\]]+)\]\]"#,
            with: "$1",
            options: .regularExpression
        ).replacingOccurrences(
            of: #"\[\[(?:[^\]/]+/)*([^\]]+)\]\]"#,
            with: "$1",
            options: .regularExpression
        )
    }
}
