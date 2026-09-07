import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class GrammarLibrary {
    private(set) var notes: [GrammarNote] = [] { didSet { updateResults() } }
    private(set) var folderURL: URL?
    private(set) var errorMessage: String?
    private(set) var warningMessage: String?
    var query = "" { didSet { if query != oldValue { updateResults() } } }
    private(set) var selectedNoteID: GrammarNote.ID?
    private(set) var results: [SearchResult] = []

    private let savedFolderKey = "grammarFolderPath"

    init(notes: [GrammarNote]? = nil) {
        if let notes {
            self.notes = notes
        } else {
            reload()
        }
    }

    private func updateResults() {
        results = GrammarSearch.search(query, in: notes)
        selectedNoteID = results.first?.id
    }

    var selectedResult: SearchResult? {
        if let selectedNoteID,
           let result = results.first(where: { $0.note.id == selectedNoteID }) {
            return result
        }
        return results.first
    }

    func select(_ result: SearchResult) {
        selectedNoteID = result.note.id
    }

    func moveSelection(by offset: Int) {
        let currentResults = results
        guard !currentResults.isEmpty else { return }

        let currentIndex = currentResults.firstIndex { $0.note.id == selectedNoteID } ?? 0
        let nextIndex = min(max(currentIndex + offset, 0), currentResults.count - 1)
        selectedNoteID = currentResults[nextIndex].note.id
    }

    func reload() {
        warningMessage = nil
        guard let savedPath = UserDefaults.standard.string(forKey: savedFolderKey) else {
            notes = []
            folderURL = nil
            errorMessage = "Choose the folder that contains your Markdown grammar notes."
            return
        }
        load(from: URL(fileURLWithPath: savedPath, isDirectory: true))
    }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose your grammar notes folder"
        panel.prompt = "Use Folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = folderURL

        guard panel.runModal() == .OK, let url = panel.url else { return }
        UserDefaults.standard.set(url.path, forKey: savedFolderKey)
        load(from: url)
    }

    func load(from folder: URL) {
        warningMessage = nil
        guard FileManager.default.fileExists(atPath: folder.path) else {
            notes = []
            folderURL = nil
            errorMessage = "Choose the folder that contains your Markdown grammar notes."
            return
        }

        do {
            let markdownFiles = try GrammarFileIndex.markdownFiles(in: folder)
            var skipped = 0
            notes = markdownFiles.compactMap { url in
                guard let markdown = try? String(contentsOf: url, encoding: .utf8) else {
                    skipped += 1
                    return nil
                }
                return GrammarNote(url: url, markdown: markdown)
            }
            if skipped > 0 {
                warningMessage = "Skipped \(skipped) unreadable file(s). Notes must be UTF-8 Markdown."
            }
            folderURL = folder
            errorMessage = nil
        } catch {
            notes = []
            folderURL = folder
            errorMessage = "Sakuin couldn’t read this folder: \(error.localizedDescription)"
        }
    }

}

enum GrammarFileIndex {
    static func markdownFiles(
        in root: URL,
        fileManager: FileManager = .default
    ) throws -> [URL] {
        let keys: [URLResourceKey] = [.isRegularFileKey]
        guard try root.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true else {
            throw CocoaError(.fileReadUnsupportedScheme)
        }
        var enumerationError: Error?
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, error in
                enumerationError = error
                return false
            }
        ) else {
            throw CocoaError(.fileReadUnknown)
        }

        let files = try enumerator.compactMap { item -> URL? in
            guard let url = item as? URL,
                  url.pathExtension.caseInsensitiveCompare("md") == .orderedSame,
                  url.deletingPathExtension().lastPathComponent.range(
                    of: #"[\p{Hiragana}\p{Katakana}\p{Han}]"#, options: .regularExpression
                  ) != nil,
                  try url.resourceValues(forKeys: Set(keys)).isRegularFile == true else {
                return nil
            }
            return url
        }
        .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
        if let enumerationError { throw enumerationError }
        return files
    }
}
