import Foundation

/// Distinguishes a local pass-and-play/AI game from a GameKit turn-based online match, so
/// `GameViewModel` knows whether to advance AI turns and persist local saves, or hand off
/// to `OnlineMatchDelegate` after every state mutation instead.
enum GameMode: Equatable {
    case local
    case online
}

enum OnlineMatchPhase: String, Codable {
    case playing
    case gameEnd
}

/// The full snapshot of a turn-based online match, encoded into `GKTurnBasedMatch.matchData`
/// by whichever device just finished its turn, and decoded by whichever device's turn is next.
/// Reuses the same `Codable` model types as the local save feature (`Player`, `Deck`,
/// `TurnDirection`) so both save paths stay in sync as the game evolves.
struct OnlineMatchState: Codable {
    var players: [Player]
    var deck: Deck
    var currentPlayerIndex: Int
    var direction: TurnDirection
    var pendingDrawStack: Int
    var phase: OnlineMatchPhase
    var roundWinnerID: UUID?
    var gameWinnerID: UUID?
    /// Maps each GameKit participant's stable `gamePlayerID` to the `Player.id` dealt into
    /// this match, agreed once by the hosting device and carried forward in every snapshot so
    /// every participant's device can tell which hand is theirs and whose turn is next.
    var participantPlayerIDs: [String: UUID]
}

/// Notified by `GameViewModel` whenever an online match's state changes, so the coordinator
/// can encode it and hand the turn to GameKit. `GameViewModel` itself has no GameKit dependency.
@MainActor
protocol OnlineMatchDelegate: AnyObject {
    func gameViewModelDidUpdateOnlineState(_ viewModel: GameViewModel)
    func gameViewModelDidEndGame(_ viewModel: GameViewModel, winnerIndex: Int)
    func gameViewModelDidRequestQuit(_ viewModel: GameViewModel)
}
