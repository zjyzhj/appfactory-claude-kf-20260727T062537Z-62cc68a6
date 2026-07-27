import SwiftUI

/// Navigation shell (PM routes hard rule): 4 persistent task-distinct tabs —
/// Viewings / Compare / Criteria / Settings. Each tab owns its NavigationStack
/// so drill-in state survives tab switches (ACC-NAV).
struct RootTabView: View {
    @State private var selectedTab: AppTab = .viewings

    enum AppTab: Hashable {
        case viewings, compare, criteria, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ViewingsListView()
                .tabItem { Label("Viewings", systemImage: "house.fill") }
                .tag(AppTab.viewings)
            CompareHomeView()
                .tabItem { Label("Compare", systemImage: "chart.bar.fill") }
                .tag(AppTab.compare)
            CriteriaHomeView()
                .tabItem { Label("Criteria", systemImage: "checklist") }
                .tag(AppTab.criteria)
            SettingsHomeView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(Theme.accentBrass)
    }
}
