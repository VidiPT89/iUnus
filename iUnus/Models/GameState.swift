import Foundation

enum GamePhase: Equatable {
    case menu
    case dealing
    case playing
    case choosingColor(pendingCard: Card)
    case roundEnd
    case gameEnd
}

enum TurnDirection: Int, Codable {
    case clockwise = 1
    case counterClockwise = -1

    mutating func toggle() {
        self = self == .clockwise ? .counterClockwise : .clockwise
    }
}

/// Tracks a player who dropped to 1 card without calling UNO. Per official rules the window to
/// catch them stays open only until the next turn begins — rather than a wall-clock timer (which
/// would drift out of sync with however many bot turns fit in it), `blockingPlayerIndex` names
/// the seat whose upcoming action closes the window, silently and without penalty, the moment it
/// resolves (see `GameViewModel.attemptPlay`/`drawForCurrentPlayer`).
struct PendingUnoCatch: Equatable, Codable {
    let playerID: UUID
    var blockingPlayerIndex: Int
}
