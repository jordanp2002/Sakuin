import AppKit
import SwiftUI

@main
enum SakuinApp {
    static func main() {
        let application = NSApplication.shared
        let delegate = SakuinAppDelegate()
        application.delegate = delegate
        application.run()
    }
}

@MainActor
final class SakuinAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let settings = AppSettings()
    private let library = GrammarLibrary()
    private let hotKey = GlobalHotKey()
    private let panel = SakuinPanelWindow()
    private var statusItem: NSStatusItem?
    private var outsideClickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "character.book.closed", accessibilityDescription: "Sakuin")
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(togglePopover)
            button.toolTip = "Sakuin — \(settings.shortcut.displayName)"
        }
        statusItem = item

        panel.delegate = self
        panel.setContentSize(settings.panelSize)
        panel.contentViewController = NSHostingController(
            rootView: SakuinPanel(library: library, settings: settings)
        )
        panel.applyRoundedContentShape()

        settings.onPanelSizeChange = { [weak self] size in self?.resizePopover(to: size) }
        settings.onShortcutChange = { [weak self] shortcut in
            self?.hotKey.register(shortcut) { [weak self] in self?.togglePopover() }
            self?.statusItem?.button?.toolTip = "Sakuin — \(shortcut.displayName)"
        }
        hotKey.register(settings.shortcut) { [weak self] in self?.togglePopover() }

    }

    @objc private func togglePopover() {
        if panel.isVisible {
            panel.close()
            return
        }
        guard let button = statusItem?.button else { return }
        showPanel(relativeTo: button)
    }

    private func showPanel(relativeTo button: NSStatusBarButton) {
        library.reload()
        NSApplication.shared.activate()
        positionPanel(relativeTo: button)
        panel.orderFrontRegardless()
        panel.makeKey()
        installOutsideClickMonitor()
        Task { @MainActor in
            NotificationCenter.default.post(name: .sakuinDidOpen, object: nil)
        }
    }

    func windowWillClose(_ notification: Notification) {
        removeOutsideClickMonitor()
    }

    func windowDidResize(_ notification: Notification) {
        settings.recordWindowResize(panel.contentView?.bounds.size ?? panel.contentLayoutRect.size)
        panel.applyRoundedContentShape()
    }

    private func installOutsideClickMonitor() {
        guard outsideClickMonitor == nil else { return }
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.panel.close()
            }
        }
    }

    private func removeOutsideClickMonitor() {
        if let outsideClickMonitor {
            NSEvent.removeMonitor(outsideClickMonitor)
            self.outsideClickMonitor = nil
        }
    }

    private func resizePopover(to size: NSSize) {
        let topLeft = NSPoint(x: panel.frame.minX, y: panel.frame.maxY)
        panel.setContentSize(size)
        panel.setFrameTopLeftPoint(topLeft)
    }

    private func positionPanel(relativeTo button: NSStatusBarButton) {
        guard let buttonWindow = button.window else { return }
        let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let visibleFrame = buttonWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        var origin = NSPoint(
            x: buttonFrame.midX - panel.frame.width / 2,
            y: buttonFrame.minY - panel.frame.height - 6
        )
        origin.x = min(max(origin.x, visibleFrame.minX + 8), visibleFrame.maxX - panel.frame.width - 8)
        origin.y = max(origin.y, visibleFrame.minY + 8)
        panel.setFrameOrigin(origin)
    }

}

final class SakuinPanelWindow: NSPanel {
    static let cornerRadius: CGFloat = 22

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = false
        level = .popUpMenu
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        isReleasedWhenClosed = false
        hasShadow = true
        backgroundColor = .clear
        isOpaque = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        contentMinSize = NSSize(width: 380, height: 480)
        contentMaxSize = NSSize(width: 620, height: 820)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func applyRoundedContentShape() {
        guard let contentView else { return }
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = Self.cornerRadius
        contentView.layer?.cornerCurve = .continuous
        contentView.layer?.masksToBounds = true
    }

    override func cancelOperation(_ sender: Any?) {
        close()
    }
}

extension Notification.Name {
    static let sakuinDidOpen = Notification.Name("SakuinDidOpen")
}
