import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Self.themeKey) }
    }

    @Published var aiDifficulty: AIDifficulty {
        didSet { UserDefaults.standard.set(aiDifficulty.rawValue, forKey: Self.difficultyKey) }
    }

    private static let themeKey = "app.theme"
    private static let difficultyKey = "app.aiDifficulty"

    init() {
        let storedTheme = UserDefaults.standard.string(forKey: Self.themeKey)
        theme = AppTheme(rawValue: storedTheme ?? "system") ?? .system

        let storedDifficulty = UserDefaults.standard.string(forKey: Self.difficultyKey)
        aiDifficulty = AIDifficulty(rawValue: storedDifficulty ?? "normal") ?? .normal
    }
}
