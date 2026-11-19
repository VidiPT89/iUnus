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
    /// Set by the menu while one of its sheets or alerts is up, to tuck the access point away.
    @Published var menuSheetIsPresented = false

    /// Apple's Game Center access point: the floating badge with the player's avatar that opens
    /// the Games overlay. Only shown on the main menu once signed in, never over the table, the
    /// splash or a sheet, so it can't cover cards or controls.
    func setAccessPointVisible(_ visible: Bool) {
        let access = GKAccessPoint.shared
        access.location = .topLeading
        let shouldShow = visible && isAuthenticated
        if access.isActive != shouldShow { access.isActive = shouldShow }
    }

    func authenticate() {
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
