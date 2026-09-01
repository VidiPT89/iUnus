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

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey) }
    }

    private static let storageKey = "app.language.override"
    private var bundle: Bundle = .main

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey)
        language = AppLanguage(rawValue: stored ?? "system") ?? .system
        updateBundle()
    }

    func setLanguage(_ language: AppLanguage) {
        self.language = language
        updateBundle()
    }

    private func updateBundle() {
        let code: String
        switch language {
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

    func string(_ key: String) -> String {
        updateBundle()
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
}

enum L {
    static func t(_ key: String) -> String {
        LocalizationManager.shared.string(key)
    }
}
