import SwiftUI

@main
struct AppLauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var launcherWindow: LauncherWindowController?
    var menuBar: MenuBarController?
    var eventTap: CFMachPort?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        AppScanner.shared.initialScan()
        launcherWindow = LauncherWindowController()
        menuBar = MenuBarController()
        menuBar?.setup()

        // Minimal main menu so Cmd-Q works when the app is active
        let mainMenu = NSMenu()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit AppLauncher", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu

        registerHotKey()
    }

    func registerHotKey() {
        let mask: CGEventMask = 1 << CGEventType.keyDown.rawValue

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, _, event, userInfo in
                guard let userInfo = userInfo else { return Unmanaged.passUnretained(event) }

                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags

                // keyCode 0 = A, check for Option (without Cmd/Ctrl/Shift)
                if keyCode == 0 &&
                    flags.contains(.maskAlternate) &&
                    !flags.contains(.maskCommand) &&
                    !flags.contains(.maskControl) &&
                    !flags.contains(.maskShift) {
                    let delegate = Unmanaged<AppDelegate>.fromOpaque(userInfo).takeUnretainedValue()
                    DispatchQueue.main.async {
                        delegate.showLauncher()
                    }
                    return nil  // consume the event
                }

                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("AppLauncher: failed to create event tap — check Accessibility permissions")
            return
        }

        self.eventTap = tap

        let runLoopSource = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        // macOS can disable event taps at any time (e.g. after permission changes);
        // periodically re-enable to recover
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let tap = self?.eventTap else { return }
            if !CGEvent.tapIsEnabled(tap: tap) {
                NSLog("AppLauncher: re-enabling event tap")
                CGEvent.tapEnable(tap: tap, enable: true)
            }
        }
    }

    @objc func showLauncher() {
        launcherWindow?.show()
    }
}
