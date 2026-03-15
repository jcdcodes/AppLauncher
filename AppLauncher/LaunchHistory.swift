import Foundation

class LaunchHistory {
    static let shared = LaunchHistory()

    private let defaults = UserDefaults.standard
    private let historyKey = "launchHistory"
    private let lastLaunchedKey = "lastLaunchedApp"

    // Hardcoded aliases: typing a prefix of the key surfaces the value
    let aliases: [String: String] = [
        "pref": "System Settings",
        "term": "Ghostty",
    ]

    /// Record that `appName` was launched after typing `query`.
    /// Stores a mapping for every prefix of the query.
    func record(query: String, appName: String) {
        defaults.set(appName, forKey: lastLaunchedKey)
        guard !query.isEmpty else { return }
        var history = defaults.dictionary(forKey: historyKey) as? [String: String] ?? [:]
        let q = query.lowercased()
        for i in 1...q.count {
            let prefix = String(q.prefix(i))
            history[prefix] = appName
        }
        defaults.set(history, forKey: historyKey)
    }

    /// Returns the name of the most recently launched app, if any.
    var lastLaunchedApp: String? {
        defaults.string(forKey: lastLaunchedKey)
    }

    /// Returns the app name that was last launched for the given query, if any.
    func boostedApp(for query: String) -> String? {
        guard !query.isEmpty else { return nil }
        let history = defaults.dictionary(forKey: historyKey) as? [String: String] ?? [:]
        return history[query.lowercased()]
    }

    /// Returns app names that should be included in results because the query
    /// matches an alias (query is a prefix of an alias key).
    func aliasMatches(for query: String) -> [String] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return aliases.compactMap { key, value in
            key.hasPrefix(q) ? value : nil
        }
    }
}
