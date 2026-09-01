import Foundation
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case portuguese = "pt-PT"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return L.t("settings.language.system")
        case .english: return "English"
        case .portuguese: return "Português"
        }
    }
}

@MainActor
final class LocalizationManager: ObservableObject {
    nonisolated(unsafe) static let shared = MainActor.assumeIsolated { LocalizationManager() }

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
            currentLanguage = language
            updateBundle()
        }
    }

    private static let storageKey = "app.language.override"
    // Mirrors `language` outside main-actor isolation so `string(_:)` can stay nonisolated,
    // letting plain model types (e.g. `Card.accessibilityLabel`) look up localized strings
    // synchronously without hopping to the main actor; this app is effectively single-threaded.
    private nonisolated(unsafe) var currentLanguage: AppLanguage = .system
    private nonisolated(unsafe) var bundle: Bundle = .main
    private nonisolated(unsafe) var cachedLanguage: AppLanguage?

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey)
        let initial = AppLanguage(rawValue: stored ?? "system") ?? .system
        language = initial
        currentLanguage = initial
        updateBundle()
    }

    private nonisolated func updateBundle() {
        guard cachedLanguage != currentLanguage else { return }
        cachedLanguage = currentLanguage
        let code: String
        switch currentLanguage {
        case .system:
            bundle = .main
            return
        case .english:
            code = "en"
        case .portuguese:
            code = "pt-PT"
        }
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            bundle = langBundle
        } else {
            bundle = .main
        }
    }

    nonisolated func string(_ key: String) -> String {
        updateBundle()
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
}

enum L {
    static func t(_ key: String) -> String {
        LocalizationManager.shared.string(key)
    }
}
