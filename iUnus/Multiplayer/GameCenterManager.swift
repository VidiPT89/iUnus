import Foundation
import GameKit

/// Wraps GKLocalPlayer authentication. The system authentication view controller is handed
/// to us asynchronously by GameKit's handler, so we surface it via `authViewController` for a
/// SwiftUI-side presenter to display, rather than presenting it ourselves.
@MainActor
final class GameCenterManager: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published var authViewController: UIViewController?
    @Published var authError: String?

    private(set) var didAttemptAuthentication = false

    func authenticate() {
        didAttemptAuthentication = true
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }
            Task { @MainActor in
                if let viewController {
                    self.authViewController = viewController
                    return
                }
                self.authViewController = nil
                if GKLocalPlayer.local.isAuthenticated {
                    self.isAuthenticated = true
                    self.authError = nil
                    NotificationCenter.default.post(name: .gameCenterDidAuthenticate, object: nil)
                } else {
                    self.isAuthenticated = false
                    self.authError = error?.localizedDescription
                }
            }
        }
    }
}

extension Notification.Name {
    static let gameCenterDidAuthenticate = Notification.Name("gameCenterDidAuthenticate")
}
