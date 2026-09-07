import AppKit
import Foundation
import Observation
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    var id: Self { self }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum ReadingSize: String, CaseIterable, Identifiable {
    case compact = "Compact"
    case standard = "Standard"
    case large = "Large"
    var id: Self { self }

    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .compact: .small
        case .standard: .medium
        case .large: .xLarge
        }
    }
}

struct KeyboardShortcut: Equatable {
    var key: String
    var command: Bool
    var option: Bool
    var control: Bool
    var shift: Bool

    static let defaultValue = KeyboardShortcut(key: "G", command: false, option: true, control: true, shift: false)

    var displayName: String {
        (control ? "⌃" : "") + (option ? "⌥" : "") + (shift ? "⇧" : "")
            + (command ? "⌘" : "") + key.uppercased()
    }
}

@MainActor
@Observable
final class AppSettings {
    var panelWidth: Double { didSet { saveSize() } }
    var panelHeight: Double { didSet { saveSize() } }
    var readingSize: ReadingSize { didSet { defaults.set(readingSize.rawValue, forKey: Keys.readingSize) } }
    var theme: AppTheme { didSet { defaults.set(theme.rawValue, forKey: Keys.theme) } }
    var shortcut: KeyboardShortcut {
        didSet {
            saveShortcut()
            onShortcutChange?(shortcut)
        }
    }

    @ObservationIgnored var onPanelSizeChange: ((NSSize) -> Void)?
    @ObservationIgnored var onShortcutChange: ((KeyboardShortcut) -> Void)?
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var isRecordingWindowResize = false

    var panelSize: NSSize { NSSize(width: panelWidth, height: panelHeight) }

    init() {
        let defaults = UserDefaults.standard
        panelWidth = defaults.object(forKey: Keys.panelWidth) as? Double ?? 460
        panelHeight = defaults.object(forKey: Keys.panelHeight) as? Double ?? 640
        readingSize = ReadingSize(rawValue: defaults.string(forKey: Keys.readingSize) ?? "") ?? .standard
        theme = AppTheme(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .system
        shortcut = KeyboardShortcut(
            key: defaults.string(forKey: Keys.shortcutKey) ?? KeyboardShortcut.defaultValue.key,
            command: defaults.object(forKey: Keys.shortcutCommand) as? Bool ?? KeyboardShortcut.defaultValue.command,
            option: defaults.object(forKey: Keys.shortcutOption) as? Bool ?? KeyboardShortcut.defaultValue.option,
            control: defaults.object(forKey: Keys.shortcutControl) as? Bool ?? KeyboardShortcut.defaultValue.control,
            shift: defaults.object(forKey: Keys.shortcutShift) as? Bool ?? KeyboardShortcut.defaultValue.shift
        )
    }

    func resetAppearance() {
        panelWidth = 460
        panelHeight = 640
        readingSize = .standard
        theme = .system
    }

    func recordWindowResize(_ size: NSSize) {
        isRecordingWindowResize = true
        panelWidth = size.width
        panelHeight = size.height
        isRecordingWindowResize = false
    }

    private func saveSize() {
        defaults.set(panelWidth, forKey: Keys.panelWidth)
        defaults.set(panelHeight, forKey: Keys.panelHeight)
        if !isRecordingWindowResize {
            onPanelSizeChange?(panelSize)
        }
    }

    private func saveShortcut() {
        defaults.set(shortcut.key, forKey: Keys.shortcutKey)
        defaults.set(shortcut.command, forKey: Keys.shortcutCommand)
        defaults.set(shortcut.option, forKey: Keys.shortcutOption)
        defaults.set(shortcut.control, forKey: Keys.shortcutControl)
        defaults.set(shortcut.shift, forKey: Keys.shortcutShift)
    }

    private enum Keys {
        static let panelWidth = "appearance.panelWidth"
        static let panelHeight = "appearance.panelHeight"
        static let readingSize = "appearance.readingSize"
        static let theme = "appearance.theme"
        static let shortcutKey = "shortcut.key"
        static let shortcutCommand = "shortcut.command"
        static let shortcutOption = "shortcut.option"
        static let shortcutControl = "shortcut.control"
        static let shortcutShift = "shortcut.shift"
    }
}
