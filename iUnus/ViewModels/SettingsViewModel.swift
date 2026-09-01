import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Self.themeKey) }
    }

    private static let themeKey = "app.theme"

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.themeKey)
        theme = AppTheme(rawValue: stored ?? "system") ?? .system
    }
}
