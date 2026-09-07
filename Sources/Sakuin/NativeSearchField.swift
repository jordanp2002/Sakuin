import AppKit
import SwiftUI

struct NativeSearchField: NSViewRepresentable {
    @Environment(\.sakuinPalette) private var colors
    @Binding var text: String
    let focusGeneration: Int
    let onMoveSelection: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onMoveSelection: onMoveSelection)
    }

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField()
        field.placeholderString = "Grammar point or meaning"
        field.isBezeled = false
        field.drawsBackground = false
        field.font = .systemFont(ofSize: 15)
        field.sendsSearchStringImmediately = true
        field.sendsWholeSearchString = false
        (field.cell as? NSSearchFieldCell)?.searchButtonCell = nil
        field.delegate = context.coordinator
        field.focusRingType = .none
        field.setAccessibilityIdentifier("grammarSearchField")
        return field
    }

    func updateNSView(_ field: NSSearchField, context: Context) {
        field.appearance = NSAppearance(named: colors.isDark ? .darkAqua : .aqua)
        field.textColor = NSColor(colors.text)
        field.placeholderAttributedString = NSAttributedString(
            string: "Grammar point or meaning",
            attributes: [.foregroundColor: NSColor(colors.muted), .font: NSFont.systemFont(ofSize: 15)]
        )
        context.coordinator.onMoveSelection = onMoveSelection
        if field.stringValue != text {
            field.stringValue = text
        }

        guard context.coordinator.lastFocusGeneration != focusGeneration else { return }
        context.coordinator.lastFocusGeneration = focusGeneration
        DispatchQueue.main.async { [weak field] in
            guard let field, let window = field.window else { return }
            window.makeFirstResponder(field)
            field.selectText(nil)
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSSearchFieldDelegate {
        @Binding private var text: String
        var onMoveSelection: (Int) -> Void
        var lastFocusGeneration = 0

        init(text: Binding<String>, onMoveSelection: @escaping (Int) -> Void = { _ in }) {
            _text = text
            self.onMoveSelection = onMoveSelection
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSSearchField else { return }
            text = field.stringValue
        }

        func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            if commandSelector == #selector(NSResponder.moveUp(_:))
                || commandSelector == #selector(NSResponder.moveLeft(_:)) {
                onMoveSelection(-1)
                return true
            }
            if commandSelector == #selector(NSResponder.moveDown(_:))
                || commandSelector == #selector(NSResponder.moveRight(_:)) {
                onMoveSelection(1)
                return true
            }

            let isReturn = commandSelector == #selector(NSResponder.insertNewline(_:))
                || NSStringFromSelector(commandSelector) == "insertNewlineIgnoringFieldEditor:"
            guard isReturn else { return false }

            if let field = control as? NSSearchField {
                text = field.stringValue
            }
            return true
        }

    }
}
