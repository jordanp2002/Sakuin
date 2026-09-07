import SwiftUI

struct AppearanceView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section("Window") {
                Slider(value: $settings.panelWidth, in: 380...620, step: 10) {
                    Text("Width: \(Int(settings.panelWidth))")
                }
                Slider(value: $settings.panelHeight, in: 480...820, step: 10) {
                    Text("Height: \(Int(settings.panelHeight))")
                }
            }
            Section("Reading") {
                Picker("Text size", selection: $settings.readingSize) {
                    ForEach(ReadingSize.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Appearance", selection: $settings.theme) {
                    ForEach(AppTheme.allCases) { Text($0.rawValue).tag($0) }
                }
                Button("Reset Appearance", action: settings.resetAppearance)
            }
            Section("Global shortcut") {
                modifier("Control", value: $settings.shortcut.control)
                modifier("Option", value: $settings.shortcut.option)
                modifier("Shift", value: $settings.shortcut.shift)
                modifier("Command", value: $settings.shortcut.command)
                Picker("Key", selection: $settings.shortcut.key) {
                    ForEach(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map(String.init), id: \.self) {
                        Text($0).tag($0)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollIndicators(.hidden)
    }

    private func modifier(_ title: String, value: Binding<Bool>) -> some View {
        Toggle(title, isOn: value)
            .disabled(value.wrappedValue &&
                [settings.shortcut.control, settings.shortcut.option,
                 settings.shortcut.shift, settings.shortcut.command].filter { $0 }.count == 1)
    }
}
