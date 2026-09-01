import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Self.themeKey) }
    }

    @Published var aiDifficulty: AIDifficulty {
        didSet { UserDefaults.standard.set(aiDifficulty.rawValue, forKey: Self.difficultyKey) }
    }

    @Published var ruleSet: RuleSet {
        didSet { UserDefaults.standard.set(ruleSet.rawValue, forKey: Self.ruleSetKey) }
    }

    private static let themeKey = "app.theme"
    private static let difficultyKey = "app.aiDifficulty"
    private static let ruleSetKey = "app.ruleSet"

    init() {
        let storedTheme = UserDefaults.standard.string(forKey: Self.themeKey)
        theme = AppTheme(rawValue: storedTheme ?? "system") ?? .system

        let storedDifficulty = UserDefaults.standard.string(forKey: Self.difficultyKey)
        aiDifficulty = AIDifficulty(rawValue: storedDifficulty ?? "normal") ?? .normal

        let storedRuleSet = UserDefaults.standard.string(forKey: Self.ruleSetKey)
        ruleSet = RuleSet(rawValue: storedRuleSet ?? "official") ?? .official
    }
}
