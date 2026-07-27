import SwiftUI

@main
struct TourWiseApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
                .environmentObject(appState.store)
                .environmentObject(appState.credits)
                .environmentObject(appState.permissions)
                .onAppear {
                    appState.permissions.refreshAll()
                }
        }
    }
}
