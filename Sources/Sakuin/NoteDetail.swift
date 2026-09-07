import SwiftUI

struct NoteDetail: View {
    @Environment(\.sakuinPalette) private var colors
    let result: SearchResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let excerpt = result.excerpt, result.matchKind != .title {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "scope")
                        Text(excerpt)
                    }
                    .font(.caption)
                    .foregroundStyle(colors.muted)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(colors.mantle, in: RoundedRectangle(cornerRadius: 10))
                }

                MarkdownNote(note: result.note)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}
