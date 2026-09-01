import Foundation

enum GamePhase: Equatable {
    case menu
    case dealing
    case playing
    case choosingColor(pendingCard: Card)
    case roundEnd
    case gameEnd
}

enum TurnDirection: Int {
    case clockwise = 1
    case counterClockwise = -1

    mutating func toggle() {
        self = self == .clockwise ? .counterClockwise : .clockwise
    }
}

struct PendingUnoCatch: Equatable {
    let playerID: UUID
    let deadline: Date
}

/// Snapshot of the last play, used to drive fly-out animation in the view layer.
struct LastMove: Equatable {
    let card: Card
    let playerID: UUID
}
