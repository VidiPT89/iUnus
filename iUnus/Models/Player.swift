import Foundation

enum PlayerKind: Codable, Equatable {
    case human
    case ai
}

struct Player: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var kind: PlayerKind
    var hand: [Card] = []
    var totalScore: Int = 0
    var hasCalledUno: Bool = false

    init(id: UUID = UUID(), name: String, kind: PlayerKind) {
        self.id = id
        self.name = name
        self.kind = kind
    }

    var isAI: Bool { kind == .ai }
}
