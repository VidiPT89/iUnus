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

/// UI changes the published preference on the main thread; model lookups can safely read
/// the resolved bundle from any thread without actor assumptions or mutable global caches.
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
            updateBundle()
        }
    }

    private static let storageKey = "app.language.override"
    private let lock = NSLock()
    private var bundle: Bundle = .main

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey)
        language = AppLanguage(rawValue: stored ?? "system") ?? .system
        updateBundle()
    }

    private func updateBundle() {
        let resolved: Bundle
        if language != .system,
           let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let selected = Bundle(path: path) {
            resolved = selected
        } else {
            resolved = .main
        }
        lock.lock()
        bundle = resolved
        lock.unlock()
    }

    func string(_ key: String) -> String {
        lock.lock()
        let selected = bundle
        lock.unlock()
        return NSLocalizedString(key, bundle: selected, comment: "")
    }
}

enum L {
    static func t(_ key: String) -> String {
        LocalizationManager.shared.string(key)
    }
}
