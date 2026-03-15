import SwiftUI

class LauncherState: ObservableObject {
    @Published var showGeneration: Int = 0

    func reset() {
        showGeneration += 1
    }
}

struct LauncherView: View {
    @ObservedObject var state: LauncherState
    @State private var query: String = ""
    @State private var allApps: [AppEntry] = []
    @State private var selectedIndex: Int = 0
    @FocusState private var searchFocused: Bool

    var onDismiss: () -> Void
    var onLaunch: (AppEntry) -> Void

    var filtered: [AppEntry] {
        if query.isEmpty {
            if let last = LaunchHistory.shared.lastLaunchedApp,
               let idx = allApps.firstIndex(where: { $0.name == last }), idx > 0 {
                var reordered = allApps
                let app = reordered.remove(at: idx)
                reordered.insert(app, at: 0)
                return reordered
            }
            return allApps
        }
        let q = query.lowercased()
        let history = LaunchHistory.shared

        // Prefix matches first, then substring matches
        var prefixMatches: [AppEntry] = []
        var substringMatches: [AppEntry] = []
        for app in allApps {
            let name = app.name.lowercased()
            if name.hasPrefix(q) {
                prefixMatches.append(app)
            } else if name.contains(q) {
                substringMatches.append(app)
            }
        }
        var results = prefixMatches + substringMatches
        let resultIDs = Set(results.map { $0.id })

        // Apps matching via aliases (e.g. "pref" → "System Settings")
        let aliasNames = Set(history.aliasMatches(for: q))
        for app in allApps where aliasNames.contains(app.name) {
            if !resultIDs.contains(app.id) {
                results.append(app)
            }
        }

        // Boost last-launched app for this prefix to the top
        if let boosted = history.boostedApp(for: q),
           let idx = results.firstIndex(where: { $0.name == boosted }), idx > 0 {
            let app = results.remove(at: idx)
            results.insert(app, at: 0)
        }

        return results
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))
                TextField("Open app…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18))
                    .focused($searchFocused)
                    .onKeyPress(.escape) {
                        onDismiss()
                        return .handled
                    }
                    .onKeyPress(.return) {
                        launch()
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        moveDown()
                        return .handled
                    }
                    .onKeyPress(.upArrow) {
                        moveUp()
                        return .handled
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if !filtered.isEmpty {
                Divider()

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { idx, app in
                                AppRow(app: app, isSelected: idx == selectedIndex)
                                    .id(app.id)
                                    .onTapGesture {
                                        selectedIndex = idx
                                        launch()
                                    }
                            }
                        }
                    }
                    .frame(maxHeight: 320)
                    .onChange(of: selectedIndex) {
                        if selectedIndex < filtered.count {
                            proxy.scrollTo(filtered[selectedIndex].id, anchor: nil)
                        }
                    }
                }
            }

            Divider()
            Text("⌘Q to quit AppLauncher")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.vertical, 6)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .frame(width: 480)
        .frame(maxHeight: .infinity, alignment: .top)
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 8)
        .onAppear {
            allApps = AppScanner.shared.apps
        }
        .onChange(of: state.showGeneration) {
            allApps = AppScanner.shared.apps
            query = ""
            selectedIndex = 0
            searchFocused = true
        }
        .onChange(of: query) {
            selectedIndex = 0
        }
    }

    private func launch() {
        guard !filtered.isEmpty, selectedIndex < filtered.count else { return }
        let app = filtered[selectedIndex]
        LaunchHistory.shared.record(query: query, appName: app.name)
        onLaunch(app)
    }

    private func moveDown() {
        if selectedIndex < filtered.count - 1 { selectedIndex += 1 }
    }

    private func moveUp() {
        if selectedIndex > 0 { selectedIndex -= 1 }
    }
}

struct AppRow: View {
    let app: AppEntry
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: app.icon)
                .resizable()
                .frame(width: 28, height: 28)
            Text(app.name)
                .font(.system(size: 15))
                .foregroundColor(isSelected ? .white : .primary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(isSelected ? Color.accentColor : Color.clear)
    }
}
