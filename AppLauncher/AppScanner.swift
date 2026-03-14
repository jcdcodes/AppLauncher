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
            scanDirectory(path, into: &apps, seen: &seen, fm: fm, recursive: true)
        }

        NSLog("AppScanner: found %d apps", apps.count)
        return apps.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    private static func scanDirectory(_ path: String, into apps: inout [AppEntry], seen: inout Set<String>, fm: FileManager, recursive: Bool) {
        let items: [String]
        do {
            items = try fm.contentsOfDirectory(atPath: path)
        } catch {
            NSLog("AppScanner: failed to read %@: %@", path, error.localizedDescription)
            return
        }
        for item in items {
            let fullPath = (path as NSString).appendingPathComponent(item)
            if item.hasSuffix(".app") {
                let name = (item as NSString).deletingPathExtension
                if seen.contains(name) { continue }
                seen.insert(name)

                let icon = NSWorkspace.shared.icon(forFile: fullPath)
                icon.size = NSSize(width: 32, height: 32)
                apps.append(AppEntry(name: name, url: URL(fileURLWithPath: fullPath), icon: icon))
            } else if recursive {
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue {
                    scanDirectory(fullPath, into: &apps, seen: &seen, fm: fm, recursive: true)
                }
            }
        }
    }
}
