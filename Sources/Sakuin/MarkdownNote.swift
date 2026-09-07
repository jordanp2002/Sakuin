import AppKit
import MarkdownUI
import SwiftUI

struct MarkdownNote: View {
    @Environment(\.sakuinPalette) private var colors
    @Environment(\.dynamicTypeSize) private var textSize
    let note: GrammarNote

    var body: some View {
        Markdown(note.markdown, baseURL: note.url.deletingLastPathComponent())
            .markdownTheme(Theme.gitHub.text {
                ForegroundColor(colors.text)
                BackgroundColor(nil)
                FontSize(textSize >= .xLarge ? 17 : textSize <= .small ? 13 : 15)
            }.link {
                ForegroundColor(colors.blue)
            }.code {
                FontFamilyVariant(.monospaced)
                ForegroundColor(colors.accent)
                BackgroundColor(colors.surface.opacity(0.5))
            }.heading1 { heading($0.label, size: 1.6) }
            .heading2 { heading($0.label, size: 1.3) }
            .heading3 { heading($0.label, size: 1.15) }
            .heading4 { heading($0.label, size: 1) }
            .heading5 { heading($0.label, size: 0.9) }
            .heading6 { heading($0.label, size: 0.85) }
            .blockquote { configuration in
                configuration.label
                    .markdownTextStyle { ForegroundColor(colors.secondary) }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(colors.mantle)
                    .overlay(alignment: .leading) { colors.accent.frame(width: 3) }
                    .markdownMargin(top: 8, bottom: 16)
            }.codeBlock { configuration in
                ScrollView(.horizontal) {
                    configuration.label
                        .markdownTextStyle {
                            FontFamilyVariant(.monospaced)
                            ForegroundColor(colors.text)
                            BackgroundColor(nil)
                        }
                        .fixedSize(horizontal: true, vertical: true)
                        .padding(12)
                }
                .scrollIndicators(.hidden)
                .background(colors.mantle)
                .markdownMargin(top: 8, bottom: 16)
            }.table { configuration in
                ScrollView(.horizontal) {
                    configuration.label
                        .markdownTableBorderStyle(.init(color: colors.border))
                        .markdownTableBackgroundStyle(.alternatingRows(colors.base, colors.mantle))
                }
                    .scrollIndicators(.hidden)
                    .markdownMargin(top: 8, bottom: 16)
            }.taskListMarker { configuration in
                Image(systemName: configuration.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundStyle(colors.accent)
            }.thematicBreak {
                colors.border.frame(height: 1).markdownMargin(top: 16, bottom: 16)
            })
            .markdownImageProvider(NoteImageProvider())
            .markdownInlineImageProvider(NoteInlineImageProvider())
            .environment(\.openURL, OpenURLAction { url in
                guard url.isFileURL else { return .systemAction }
                return NSWorkspace.shared.open(url.absoluteURL) ? .handled : .discarded
            })
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }
    private func heading(_ label: some View, size: Double) -> some View {
        label
            .markdownTextStyle {
                FontWeight(.semibold)
                FontSize(.em(size))
                ForegroundColor(colors.accent)
            }
            .markdownMargin(top: 20, bottom: 10)
    }
}

private struct NoteImageProvider: ImageProvider {
    @ViewBuilder func makeImage(url: URL?) -> some View {
        if let url, url.isFileURL {
            if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Label("Image unavailable", systemImage: "photo")
            }
        } else {
            DefaultImageProvider.default.makeImage(url: url)
        }
    }
}

struct NoteInlineImageProvider: InlineImageProvider {
    func image(with url: URL, label: String) async throws -> Image {
        guard url.isFileURL else {
            return try await DefaultInlineImageProvider.default.image(with: url, label: label)
        }
        guard let image = NSImage(contentsOf: url) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return Image(nsImage: image)
    }
}
