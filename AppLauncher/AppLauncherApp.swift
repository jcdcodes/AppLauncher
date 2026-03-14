import SwiftUI
import Carbon

@main
struct AppLauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var launcherWindow: LauncherWindowController?
    var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // No dock icon

        launcherWindow = LauncherWindowController()

        registerHotKey()
    }

    func registerHotKey() {
        // Option+A: keyCode 0 = A, optionKey modifier
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x4150_504C) // 'APPL'
        hotKeyID.id = 1

        let keyCode: UInt32 = 0       // A key
        let modifiers = UInt32(optionKey)

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            delegate.showLauncher()
            return noErr
        }, 1, &eventSpec, Unmanaged.passUnretained(self).toOpaque(), nil)

        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    @objc func showLauncher() {
        launcherWindow?.show()
    }
}
