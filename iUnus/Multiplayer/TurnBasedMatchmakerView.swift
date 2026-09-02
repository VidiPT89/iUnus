import SwiftUI
import GameKit

/// Bridges Apple's built-in turn-based matchmaking UI (invite friends, auto-match, view
/// existing matches). On a successful match, GameKit dismisses this view controller itself and
/// delivers the new match via the `GKLocalPlayerListener` turn-event callback — this delegate
/// only needs to handle cancellation and failure.
struct TurnBasedMatchmakerView: UIViewControllerRepresentable {
    let minPlayers: Int
    let maxPlayers: Int
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    func makeUIViewController(context: Context) -> GKTurnBasedMatchmakerViewController {
        let request = GKMatchRequest()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
        let viewController = GKTurnBasedMatchmakerViewController(matchRequest: request)
        viewController.turnBasedMatchmakerDelegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: GKTurnBasedMatchmakerViewController, context: Context) {}

    final class Coordinator: NSObject, GKTurnBasedMatchmakerViewControllerDelegate {
        private let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func turnBasedMatchmakerViewControllerWasCancelled(_ viewController: GKTurnBasedMatchmakerViewController) {
            onDismiss()
        }

        func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFailWithError error: Error) {
            onDismiss()
        }
    }
}
