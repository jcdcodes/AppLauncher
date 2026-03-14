import AppKit

struct AppEntry: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let icon: NSImage
}

class AppScanner {
    static func scanApps() -> [AppEntry] {
        let searchPaths = [
            "/Applications",
            "/System/Applications",
            (NSHomeDirectory() as NSString).appendingPathComponent("Applications")
        ]

        var apps: [AppEntry] = []
        var seen = Set<String>()
        let fm = FileManager.default

        for path in searchPaths {
            let items: [String]
            do {
                items = try fm.contentsOfDirectory(atPath: path)
            } catch {
                NSLog("AppScanner: failed to read %@: %@", path, error.localizedDescription)
                continue
            }
            for item in items {
                guard item.hasSuffix(".app") else { continue }
                let fullPath = (path as NSString).appendingPathComponent(item)
                let url = URL(fileURLWithPath: fullPath)
                let name = (item as NSString).deletingPathExtension

                if seen.contains(name) { continue }
                seen.insert(name)

                let icon = NSWorkspace.shared.icon(forFile: fullPath)
                icon.size = NSSize(width: 32, height: 32)
                apps.append(AppEntry(name: name, url: url, icon: icon))
            }
        }

        NSLog("AppScanner: found %d apps", apps.count)
        return apps.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
}
