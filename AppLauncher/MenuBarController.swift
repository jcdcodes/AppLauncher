import AppKit

class MenuBarController {
    private var statusItem: NSStatusItem?
    private let defaults = UserDefaults.standard
    private let hideUntilKey = "menuBarHiddenUntil"

    func setup() {
        if let hideUntil = defaults.object(forKey: hideUntilKey) as? Date, Date() < hideUntil {
            // Still hidden — schedule a timer to restore it
            let remaining = hideUntil.timeIntervalSinceNow
            Timer.scheduledTimer(withTimeInterval: remaining, repeats: false) { [weak self] _ in
                self?.showStatusItem()
            }
            return
        }
        showStatusItem()
    }

    private func showStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "AppLauncher")
        item.menu = buildMenu()
        self.statusItem = item
    }

    private func hideStatusItem(for interval: TimeInterval) {
        let hideUntil = Date().addingTimeInterval(interval)
        defaults.set(hideUntil, forKey: hideUntilKey)
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
        Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.showStatusItem()
        }
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        menu.addItem(withTitle: "About AppLauncher", action: #selector(showAbout), keyEquivalent: "")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Hide for 1 Day", action: #selector(hideOneDay), keyEquivalent: "")
            .target = self
        menu.addItem(withTitle: "Hide for 1 Week", action: #selector(hideOneWeek), keyEquivalent: "")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit AppLauncher", action: #selector(quit), keyEquivalent: "q")
            .target = self

        return menu
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func hideOneDay() {
        hideStatusItem(for: 86400)
    }

    @objc private func hideOneWeek() {
        hideStatusItem(for: 604800)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
