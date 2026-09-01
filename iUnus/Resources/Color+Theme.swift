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
