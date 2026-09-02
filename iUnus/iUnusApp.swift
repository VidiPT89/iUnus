import SwiftUI

@main
struct iUnusApp: App {
    @StateObject private var settings = SettingsViewModel()
    @StateObject private var gameCenterManager = GameCenterManager()
    @StateObject private var onlineMatchCoordinator = OnlineMatchCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(gameCenterManager)
                .environmentObject(onlineMatchCoordinator)
        }
    }
}
