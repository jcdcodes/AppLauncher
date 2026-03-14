import AppKit

struct AppEntry: Identifiable {
    let id: String  // use bundle path as stable identity
    let name: String
    let url: URL
    let icon: NSImage
}

class AppScanner {
    static let shared = AppScanner()

    private var cachedApps: [AppEntry] = []
    private let queue = DispatchQueue(label: "com.local.AppLauncher.scanner")

    var apps: [AppEntry] { cachedApps }

    func initialScan() {
        cachedApps = Self.scanApps()
        startWatching()
    }

    func refreshInBackground() {
        queue.async { [weak self] in
            let apps = Self.scanApps()
            DispatchQueue.main.async {
                self?.cachedApps = apps
            }
        }
    }

    // MARK: - FSEvents

    private var eventStream: FSEventStreamRef?

    private func startWatching() {
        let paths = [
            "/Applications" as CFString,
            "/System/Applications" as CFString,
        ] as CFArray

        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        guard let stream = FSEventStreamCreate(
            nil,
            { _, info, _, _, _, _ in
                guard let info = info else { return }
                let scanner = Unmanaged<AppScanner>.fromOpaque(info).takeUnretainedValue()
                scanner.refreshInBackground()
            },
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            2.0,  // debounce: 2 seconds
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagNone)
        ) else { return }

        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        FSEventStreamStart(stream)
        eventStream = stream
    }

    // MARK: - Scanning

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

        return apps.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    private static func scanDirectory(_ path: String, into apps: inout [AppEntry], seen: inout Set<String>, fm: FileManager, recursive: Bool) {
        let items: [String]
        do {
            items = try fm.contentsOfDirectory(atPath: path)
        } catch {
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
                apps.append(AppEntry(name: name, url: URL(fileURLWithPath: fullPath), icon: icon, id: fullPath))
            } else if recursive {
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue {
                    scanDirectory(fullPath, into: &apps, seen: &seen, fm: fm, recursive: true)
                }
            }
        }
    }
}

private extension AppEntry {
    init(name: String, url: URL, icon: NSImage, id: String) {
        self.id = id
        self.name = name
        self.url = url
        self.icon = icon
    }
}
