import AppKit
import Foundation
import SwiftUI
import Testing
@testable import Sakuin

@MainActor
struct NoteLoadingTests {
    @Test func loadsNestedNotesWithDuplicateNamesAndSkipsInvalidUTF8() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let nested = root.appendingPathComponent("好きな分類/notes with spaces")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try "No headings required".write(to: root.appendingPathComponent("こと.md"), atomically: true, encoding: .utf8)
        let source = "# A different title\r\n\r\n日本語 **bold**"
        try source.write(to: nested.appendingPathComponent("こと.MD"), atomically: true, encoding: .utf8)
        try Data([0xFF, 0xFE, 0xFF]).write(to: nested.appendingPathComponent("壊れた.md"))

        let library = GrammarLibrary(notes: [])
        library.load(from: root)
        library.query = "こと"
        #expect(library.results.count == 2)
        #expect(Set(library.results.map(\.id)).count == 2)
        #expect(library.notes.contains { $0.markdown == source })
        #expect(library.errorMessage == nil)
        #expect(library.warningMessage != nil)

        try FileManager.default.removeItem(at: nested.appendingPathComponent("壊れた.md"))
        library.load(from: root)
        #expect(library.warningMessage == nil)
        library.load(from: root.appendingPathComponent("missing"))
        #expect(library.notes.isEmpty)
        #expect(library.errorMessage != nil)
    }

    @Test func loadsRelativeLocalImagesWithJapaneseNamesAndSpaces() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appendingPathComponent("notes/nested", isDirectory: true)
        let assets = root.appendingPathComponent("notes/画像", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)
        let bitmap = try #require(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
            isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ))
        let png = try #require(bitmap.representation(using: .png, properties: [:]))
        try png.write(to: assets.appendingPathComponent("例 文.png"))
        let path = try #require("../画像/例 文.png".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed))
        let url = try #require(URL(string: path, relativeTo: folder)?.absoluteURL)
        _ = try await NoteInlineImageProvider().image(with: url, label: "Example")
    }

    @Test func rendersMixedMarkdownWithoutRequiringATemplate() throws {
        let source = """
        # A heading different from the filename

        日本語 with **bold**, *italic*, ~~strikethrough~~ and `inline code`.

        > A quote
        >
        > - A nested list
        >   - Another item

        1. First
        2. Second

        - [x] Complete
        - [ ] Pending

        | Grammar | Meaning |
        | --- | --- |
        | 気味 | A slight tendency |

        ```text
        # This is code, not a heading
        [[preserve this literally]]
        ```

        [Relative note](../こと.md)
        """
        let note = GrammarNote(url: URL(fileURLWithPath: "/Notes/気味.md"), markdown: source)
        let view = NSHostingView(rootView: MarkdownNote(note: note)
            .padding(20).frame(width: 440).background(.white)
            .environment(\.colorScheme, .light))
        view.setFrameSize(view.fittingSize)
        view.layoutSubtreeIfNeeded()
        let bitmap = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        #expect(bitmap.pixelsHigh > 400)
    }
}
