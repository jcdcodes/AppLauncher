import AppKit
import SwiftUI

class KeyableWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class LauncherWindowController {
    private var window: KeyableWindow?
    private var monitor: Any?
    private var previousApp: NSRunningApplication?

    func show() {
        createWindow()

        guard let window = window else { return }

        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - window.frame.width / 2
            let y = screenRect.midY + 100
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        previousApp = NSWorkspace.shared.frontmostApplication
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        DispatchQueue.main.async {
            if let contentView = window.contentView,
               let textField = self.findTextField(in: contentView) {
                window.makeFirstResponder(textField)
            }
        }

        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hide()
        }
    }

    private func hide() {
        window?.orderOut(nil)
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        previousApp?.activate()
        previousApp = nil
    }

    private func findTextField(in view: NSView) -> NSTextField? {
        if let tf = view as? NSTextField, tf.isEditable {
            return tf
        }
        for subview in view.subviews {
            if let found = findTextField(in: subview) {
                return found
            }
        }
        return nil
    }

    private func createWindow() {
        let view = LauncherView(
            onDismiss: { [weak self] in self?.hide() },
            onLaunch: { [weak self] app in
                self?.hide()
                NSWorkspace.shared.openApplication(at: app.url, configuration: NSWorkspace.OpenConfiguration())
            }
        )

        let win = KeyableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 400),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        let hosting = NSHostingView(rootView: view)
        hosting.frame = win.contentView!.bounds
        hosting.autoresizingMask = [.width, .height]
        win.contentView!.addSubview(hosting)

        win.isOpaque = false
        win.backgroundColor = .clear
        win.level = .floating
        win.hasShadow = false
        win.isReleasedWhenClosed = false
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.becomesKeyOnlyIfNeeded = false
        win.isFloatingPanel = true

        self.window = win
    }
}
