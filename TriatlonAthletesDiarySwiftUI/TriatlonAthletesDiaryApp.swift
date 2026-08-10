import SwiftUI

@main
struct TriatlonAthletesDiaryApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var store = DiaryStore.shared

    init() { FontRegistrar.registerBundledFonts() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}
