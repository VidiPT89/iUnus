import Foundation

struct SavedGame: Codable {
    var players: [Player]
    var deck: Deck
    var currentPlayerIndex: Int
    var direction: TurnDirection
    var pendingDrawStack: Int
    var roundFinishOrder: [UUID] = []
}

enum GameSaveStore {
    private static let storageKey = "app.savedGame"

    static var hasSave: Bool {
        UserDefaults.standard.data(forKey: storageKey) != nil
    }

    static func save(_ game: SavedGame) {
        guard let data = try? JSONEncoder().encode(game) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    /// Defensive load: any decode failure or structurally inconsistent save (out-of-range
    /// turn index, no human player, implausible player count) is treated as corrupt and
    /// discarded rather than risking a crash or a broken resume.
    static func load() -> SavedGame? {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(SavedGame.self, from: data),
              decoded.isValid else {
            clear()
            return nil
        }
        return decoded
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

private extension SavedGame {
    var isValid: Bool {
        guard players.count >= 2, players.count <= 4 else { return false }
        guard players.indices.contains(currentPlayerIndex) else { return false }
        guard players.contains(where: { !$0.isAI }) else { return false }
        // House Rules' "last player standing" round variant leaves finished players with an
        // empty hand mid-round; only players NOT yet recorded as finished must still hold cards.
        guard players.allSatisfy({ !$0.hand.isEmpty || roundFinishOrder.contains($0.id) }) else { return false }
        guard players.contains(where: { !$0.hand.isEmpty }) else { return false }
        return true
    }
}
