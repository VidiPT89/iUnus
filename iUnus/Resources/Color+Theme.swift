import SwiftUI

extension Color {
    /// Burnt-orange / amber-yellow / near-black brand palette (ividi.dev), used for chrome — never for card faces.
    static let brandPrimary = Color("BrandPrimary")
    static let brandSecondary = Color("BrandSecondary")
    static let brandBackground = Color("BrandBackground")
    static let brandSurface = Color("BrandSurface")
    static let brandTextPrimary = Color("BrandTextPrimary")
    static let brandTextSecondary = Color("BrandTextSecondary")
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var titleKey: String {
        switch self {
        case .system: return "settings.theme.system"
        case .light: return "settings.theme.light"
        case .dark: return "settings.theme.dark"
        }
    }
}

enum AIDifficulty: String, CaseIterable, Identifiable {
    case easy, normal, hard

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .easy: return "settings.difficulty.easy"
        case .normal: return "settings.difficulty.normal"
        case .hard: return "settings.difficulty.hard"
        }
    }
}

enum AISpeed: String, CaseIterable, Identifiable {
    case slow, normal, fast

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .slow: return "settings.aiSpeed.slow"
        case .normal: return "settings.aiSpeed.normal"
        case .fast: return "settings.aiSpeed.fast"
        }
    }

    var delayRange: ClosedRange<Double> {
        switch self {
        case .slow: return 1.6...2.6
        case .normal: return 0.8...1.6
        case .fast: return 0.3...0.7
        }
    }
}

enum RuleSet: String, CaseIterable, Identifiable {
    case official, houseRules

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .official: return "settings.ruleSet.official"
        case .houseRules: return "settings.ruleSet.houseRules"
        }
    }

    var subtitleKey: String {
        switch self {
        case .official: return "settings.ruleSet.official.subtitle"
        case .houseRules: return "settings.ruleSet.houseRules.subtitle"
        }
    }
}
