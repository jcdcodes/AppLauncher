import AppKit
import SwiftUI

class KeyableWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class LauncherWindowController {
    private let window: KeyableWindow
    private let state = LauncherState()
    private var previousApp: NSRunningApplication?
    private var textField: NSTextField?

    init() {
        let view = LauncherView(
            state: state,
            onDismiss: {},  // placeholder, replaced below
            onLaunch: { _ in }
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

        // Now rewire callbacks with actual self reference
        let updatedView = LauncherView(
            state: state,
            onDismiss: { [weak self] in self?.dismiss() },
            onLaunch: { [weak self] app in
                self?.dismiss()
                NSWorkspace.shared.openApplication(at: app.url, configuration: NSWorkspace.OpenConfiguration())
            }
        )
        hosting.rootView = updatedView

        // Cache the text field reference after layout
        DispatchQueue.main.async {
            self.textField = self.findTextField(in: win.contentView!)
        }

        // Dismiss when window loses focus (Cmd+Tab, clicking another app, etc.)
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: win,
            queue: .main
        ) { [weak self] _ in
            self?.hide()
        }
    }

    func show() {
        // If already visible, just refocus
        if window.isVisible {
            state.reset()
            focusTextField()
            return
        }

        state.reset()

        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main
        if let screen = screen {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - window.frame.width / 2
            // Center vertically with a slight upward bias, clamped to visible screen
            let y = min(
                screenRect.midY - window.frame.height / 2 + 100,
                screenRect.maxY - window.frame.height
            )
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        previousApp = NSWorkspace.shared.frontmostApplication
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        focusTextField()
    }

    private func focusTextField() {
        if let tf = textField {
            window.makeFirstResponder(tf)
        } else {
            // Fallback: find and cache it
            if let tf = findTextField(in: window.contentView!) {
                textField = tf
                window.makeFirstResponder(tf)
            }
        }
    }

    /// User-initiated dismiss (Escape, launching an app) — reactivate previous app
    private func dismiss() {
        guard window.isVisible else { return }
        let app = previousApp
        previousApp = nil
        window.orderOut(nil)
        app?.activate()
    }

    /// External focus loss (Cmd+Tab, clicked another app) — just hide, other app already has focus
    private func hide() {
        guard window.isVisible else { return }
        previousApp = nil
        window.orderOut(nil)
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
}
