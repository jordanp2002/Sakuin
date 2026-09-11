import SwiftUI

struct SakuinPanel: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var library: GrammarLibrary
    @Bindable var settings: AppSettings
    @State private var showingAppearance = false
    @State private var searchFocusGeneration = 0
    private let panelCornerRadius = SakuinPanelWindow.cornerRadius

    private var colors: SakuinColors {
        SakuinColors(isDark: (settings.theme.colorScheme ?? colorScheme) == .dark)
    }

    private var resultPickerHeight: CGFloat {
        let availableWidth = max(0, settings.panelWidth - 20)
        let columns = max(1, Int((availableWidth + 6) / 136))
        let rows = (library.results.count + columns - 1) / columns
        let rowHeight: CGFloat = 34
        let spacing = CGFloat(max(0, rows - 1) * 6)
        return min(100, CGFloat(rows) * rowHeight + spacing + 20)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if let warning = library.warningMessage {
                Text(warning)
                    .font(.caption)
                    .padding(8)
            }
            colors.border.opacity(0.5).frame(height: 1)
            Group {
                if showingAppearance {
                    AppearanceView(settings: settings)
                } else {
                    reader
                }
            }
            .transition(.opacity)
            colors.border.opacity(0.5).frame(height: 1)
            footer
        }
        .frame(
            minWidth: 380,
            maxWidth: .infinity,
            minHeight: 480,
            maxHeight: .infinity
        )
        .background(colors.base)
        .clipShape(RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous)
                .strokeBorder(colors.border.opacity(0.6), lineWidth: 0.75)
        }
        .contentShape(RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous))
        .environment(\.sakuinPalette, colors)
        .environment(\.colorScheme, settings.theme.colorScheme ?? colorScheme)
        .preferredColorScheme(settings.theme.colorScheme)
        .foregroundStyle(colors.text)
        .tint(colors.accent)
        .dynamicTypeSize(settings.readingSize.dynamicTypeSize)
        .onReceive(NotificationCenter.default.publisher(for: .sakuinDidOpen)) { _ in
            if !showingAppearance { searchFocusGeneration += 1 }
        }
        .animation(.easeInOut(duration: 0.14), value: showingAppearance)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                Button {
                    if showingAppearance {
                        showingAppearance = false
                        searchFocusGeneration += 1
                    }
                } label: {
                    Image(systemName: showingAppearance ? "chevron.left" : "character.book.closed.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(showingAppearance ? colors.secondary : Color.white)
                        .frame(width: 30, height: 30)
                        .background(showingAppearance ? colors.surface : colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(.plain)
                .allowsHitTesting(showingAppearance)
                .accessibilityLabel(showingAppearance ? "Back to search" : "Sakuin")

                Text(showingAppearance ? "Settings" : "Sakuin")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                if !showingAppearance {
                    Text("索引")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(colors.muted)
                }
                SakuinIconButton(
                    icon: showingAppearance ? "checkmark" : "slider.horizontal.3",
                    label: showingAppearance ? "Done" : "Settings"
                ) {
                    showingAppearance.toggle()
                    if !showingAppearance { searchFocusGeneration += 1 }
                }
            }

            if !showingAppearance { searchField }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 13)
        .foregroundStyle(colors.text)
        .background(colors.mantle)
    }

    private var searchField: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(colors.muted)

            NativeSearchField(
                text: $library.query,
                focusGeneration: searchFocusGeneration,
                onMoveSelection: library.moveSelection
            )
            .frame(maxWidth: .infinity)
        }
            .frame(height: 24)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(colors.base, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(colors.border, lineWidth: 1)
            }
    }

    private var reader: some View {
        Group {
            if let error = library.errorMessage {
                ContentUnavailableView {
                    Label("No notes folder", systemImage: "folder.badge.questionmark")
                } description: {
                    Text(error)
                } actions: {
                    Button("Choose Folder", action: library.chooseFolder)
                }
            } else if library.notes.isEmpty {
                ContentUnavailableView("No Markdown notes", systemImage: "doc.text")
            } else if GrammarSearch.normalize(library.query).isEmpty {
                ContentUnavailableView {
                    Label("Search grammar", systemImage: "magnifyingglass")
                } description: {
                    Text("Enter a grammar point or meaning to search your notes.")
                }
            } else if library.results.isEmpty {
                ContentUnavailableView.search(text: library.query)
            } else {
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 6) {
                                ForEach(library.results) { result in
                                    Button { library.select(result) } label: {
                                        Text(result.note.title)
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(8)
                                            .background(
                                                library.selectedNoteID == result.id
                                                    ? colors.accent.opacity(0.18) : colors.mantle,
                                                in: RoundedRectangle(cornerRadius: 6)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .help(result.note.url.path)
                                    .id(result.id)
                                }
                            }
                            .padding(10)
                        }
                        .scrollIndicators(.hidden)
                        .onChange(of: library.selectedNoteID) { _, id in
                            if let id { proxy.scrollTo(id) }
                        }
                    }
                    .frame(height: resultPickerHeight, alignment: .top)
                    colors.border.opacity(0.5).frame(height: 1)
                    if let result = library.selectedResult {
                        NoteDetail(result: result)
                            .id(result.id)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.base)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(colors.success)
                .frame(width: 6, height: 6)
            Text("\(library.notes.count) notes")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(colors.muted)
            Spacer()
            SakuinIconButton(icon: "folder", label: "Choose notes folder", action: library.chooseFolder)
            SakuinIconButton(icon: "arrow.clockwise", label: "Refresh notes", action: library.reload)
            SakuinIconButton(icon: "power", label: "Quit Sakuin") { NSApplication.shared.terminate(nil) }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(colors.mantle)
    }
}
