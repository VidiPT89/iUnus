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

struct PendingUnoCatch: Equatable, Codable {
    let playerID: UUID
    let deadline: Date
}
