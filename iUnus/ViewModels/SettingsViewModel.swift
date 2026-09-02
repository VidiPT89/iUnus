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

    @Published var aiSpeed: AISpeed {
        didSet { UserDefaults.standard.set(aiSpeed.rawValue, forKey: Self.aiSpeedKey) }
    }

    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: Self.soundEnabledKey) }
    }

    private static let themeKey = "app.theme"
    private static let difficultyKey = "app.aiDifficulty"
    private static let ruleSetKey = "app.ruleSet"
    private static let aiSpeedKey = "app.aiSpeed"
    private static let soundEnabledKey = "app.soundEnabled"

    init() {
        let storedTheme = UserDefaults.standard.string(forKey: Self.themeKey)
        theme = AppTheme(rawValue: storedTheme ?? "system") ?? .system

        let storedDifficulty = UserDefaults.standard.string(forKey: Self.difficultyKey)
        aiDifficulty = AIDifficulty(rawValue: storedDifficulty ?? "normal") ?? .normal

        let storedRuleSet = UserDefaults.standard.string(forKey: Self.ruleSetKey)
        ruleSet = RuleSet(rawValue: storedRuleSet ?? "official") ?? .official

        let storedAISpeed = UserDefaults.standard.string(forKey: Self.aiSpeedKey)
        aiSpeed = AISpeed(rawValue: storedAISpeed ?? "normal") ?? .normal

        soundEnabled = (UserDefaults.standard.object(forKey: Self.soundEnabledKey) as? Bool) ?? true
    }
}
