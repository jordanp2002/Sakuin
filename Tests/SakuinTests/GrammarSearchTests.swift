import Foundation
import AppKit
import SwiftUI
import Testing
@testable import Sakuin

struct GrammarSearchTests {
    @Test func ranksTitlesBeforeHeadingsAndBody() {
        let names = ["other", "heading", "xこと", "ことがある", "もの・こと", "こと"]
        let notes = names.map { note(named: $0, markdown: $0 == "heading" ? "## こと" : "Contains こと") }
        #expect(GrammarSearch.search("こと", in: notes).map(\.note.title) == names.reversed())
    }

    @Test(arguments: ["ば 〜 のに", "ば～のに", "ばのに"])
    func normalizesGrammarNotation(query: String) {
        #expect(GrammarSearch.search(query, in: [note(named: "ば〜のに", markdown: "")]).first?.matchKind == .title)
    }

    @Test func preservesWikiLinkLabelsInExcerpts() {
        let source = "See [[N3/気味|slight tendency]] and [[N4/とか]]."
        #expect(MarkdownText.resolvingWikiLinks(source) == "See slight tendency and とか.")
        #expect(GrammarSearch.search("slight", in: [note(named: "other", markdown: source)]).first?.excerpt == "See slight tendency and とか.")
    }
    private func note(named name: String, markdown: String) -> GrammarNote {
        GrammarNote(
            url: URL(fileURLWithPath: "/Grammar/N3/\(name).md"),
            markdown: markdown
        )
    }

    @Test func exactTitleBeatsExampleSentenceBodyMatch() {
        let exact = note(named: "気味", markdown: "# 気味\n\n## Core idea\nA slight tendency")
        let example = note(named: "そう", markdown: "# そう\n\n- 今日は風邪気味です。")

        let results = GrammarSearch.search("気味", in: [example, exact])

        #expect(results.map(\.note.title) == ["気味", "そう"])
        #expect(results[0].matchKind == .title)
        #expect(results[1].matchKind == .body)
    }

    @Test func titleVariantsAreSearchable() {
        let note = note(named: "てしまう・ちゃう", markdown: "# てしまう・ちゃう\n\n## Core idea")

        let results = GrammarSearch.search("ちゃう", in: [note])

        #expect(results.first?.score == 950)
    }

    @Test func filenameIsTheCanonicalGrammarPoint() {
        let note = note(named: "こと", markdown: "# A reusable explanation\n\n## Core idea")

        #expect(note.title == "こと")
        #expect(note.headings == ["A reusable explanation", "Core idea"])
        #expect(GrammarSearch.search("こと", in: [note]).first?.matchKind == .title)
    }

    @Test func emptyQueryDoesNotSelectADefaultGrammarPoint() {
        let note = note(named: "こと", markdown: "# こと\n\nA nominalizer")

        #expect(GrammarSearch.search("", in: [note]).isEmpty)
        #expect(GrammarSearch.search("   ", in: [note]).isEmpty)
    }

    @Test func aBodyMatchProducesOnlyOneResultPerNote() {
        let note = note(
            named: "ことがある",
            markdown: "# ことがある\n\nSometimes\n\n- Sometimes it rains\n- Sometimes I walk"
        )

        let results = GrammarSearch.search("Sometimes", in: [note])

        #expect(results.count == 1)
        #expect(results.first?.matchKind == .body)
    }
}

struct GrammarFileIndexTests {
    @Test func recursivelyFindsMarkdownFilesInAnyDirectoryLayout() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appending(
            path: "SakuinTests-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        defer { try? fileManager.removeItem(at: root) }

        let nested = root.appending(path: "any/layout/works", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: nested, withIntermediateDirectories: true)
        let topLevelNote = root.appending(path: "こと.md")
        let nestedNote = nested.appending(path: "気味.MD")
        let ignoredFile = nested.appending(path: "notes.txt")
        try "# こと".write(to: topLevelNote, atomically: true, encoding: .utf8)
        try "# 気味".write(to: nestedNote, atomically: true, encoding: .utf8)
        try "not Markdown".write(to: ignoredFile, atomically: true, encoding: .utf8)
        try "hidden".write(to: root.appending(path: ".hidden.md"), atomically: true, encoding: .utf8)

        for title in ["README", "N3", "Grammar Index", "123"] {
            try "# 日本語".write(to: nested.appending(path: "\(title).md"), atomically: true, encoding: .utf8)
        }
        for title in ["カタカナ", "N3 気味", "ﾃｽﾄ"] {
            try "note".write(to: nested.appending(path: "\(title).md"), atomically: true, encoding: .utf8)
        }
        let files = try GrammarFileIndex.markdownFiles(in: root)

        #expect(Set(files.map(\.lastPathComponent)) == ["こと.md", "気味.MD", "カタカナ.md", "N3 気味.md", "ﾃｽﾄ.md"])
        #expect(throws: (any Error).self) {
            try GrammarFileIndex.markdownFiles(in: ignoredFile)
        }
        #expect(throws: (any Error).self) {
            try GrammarFileIndex.markdownFiles(in: root.appending(path: "missing"))
        }
    }
}

@MainActor
struct GrammarLibraryNavigationTests {
    @Test func changingQueryResetsSelectionAndClearsStaleResults() {
        let library = GrammarLibrary(notes: ["こと", "ことがある", "気味"].map {
            GrammarNote(url: URL(fileURLWithPath: "/Grammar/\($0).md"), markdown: "")
        })
        library.query = "こと"
        library.moveSelection(by: 1)
        #expect(library.selectedResult?.note.title == "ことがある")
        library.query = "気味"
        #expect(library.selectedResult?.note.title == "気味")
        library.query = "missing"
        #expect(library.results.isEmpty)
        #expect(library.selectedNoteID == nil)
        library.moveSelection(by: 1)
        #expect(library.selectedResult == nil)
    }
    @Test func arrowNavigationMovesAndClampsTheSelectedResult() {
        let notes = ["こと", "ことがある", "たことがある"].map { name in
            GrammarNote(
                url: URL(fileURLWithPath: "/Grammar/\(name).md"),
                markdown: "# \(name)"
            )
        }
        let library = GrammarLibrary(notes: notes)
        library.query = "こと"
        let results = library.results

        library.select(results[0])
        library.moveSelection(by: 1)
        #expect(library.selectedNoteID == results[1].id)

        library.moveSelection(by: 10)
        #expect(library.selectedNoteID == results[2].id)

        library.moveSelection(by: -10)
        #expect(library.selectedNoteID == results[0].id)
    }
}

@MainActor
struct NativeSearchFieldTests {
    @Test func returnIsConsumedInsideSearchField() {
        let coordinator = NativeSearchField.Coordinator(text: .constant("気味"))

        let handled = coordinator.control(
            NSSearchField(),
            textView: NSTextView(),
            doCommandBy: #selector(NSResponder.insertNewline(_:))
        )

        #expect(handled)
    }

    @Test func arrowKeysNavigateSearchResults() {
        var movements: [Int] = []
        let coordinator = NativeSearchField.Coordinator(
            text: .constant("こと"),
            onMoveSelection: { movements.append($0) }
        )
        let field = NSSearchField()
        let editor = NSTextView()

        let handledUp = coordinator.control(field, textView: editor, doCommandBy: #selector(NSResponder.moveUp(_:)))
        let handledDown = coordinator.control(field, textView: editor, doCommandBy: #selector(NSResponder.moveDown(_:)))
        let handledLeft = coordinator.control(field, textView: editor, doCommandBy: #selector(NSResponder.moveLeft(_:)))
        let handledRight = coordinator.control(field, textView: editor, doCommandBy: #selector(NSResponder.moveRight(_:)))

        #expect(handledUp)
        #expect(handledDown)
        #expect(handledLeft)
        #expect(handledRight)
        #expect(movements == [-1, 1, -1, 1])
    }

    @Test func typingUpdatesResultsWithoutSubmittingOrReopening() {
        var query = ""
        let binding = Binding(
            get: { query },
            set: { query = $0 }
        )
        let coordinator = NativeSearchField.Coordinator(text: binding)
        let field = NSSearchField()
        field.stringValue = "気味"

        coordinator.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))

        let matchingNote = GrammarNote(
            url: URL(fileURLWithPath: "/Grammar/N3/気味.md"),
            markdown: "# 気味\n\nA slight tendency"
        )
        #expect(query == "気味")
        #expect(GrammarSearch.search(query, in: [matchingNote]).first?.note.title == "気味")
    }
}
