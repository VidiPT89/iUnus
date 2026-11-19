import Foundation

struct SavedGame: Codable {
    var players: [Player]
    var deck: Deck
    var currentPlayerIndex: Int
    var direction: TurnDirection
    var pendingDrawStack: Int
    var roundFinishOrder: [UUID] = []
    var drawnCardToPlayID: UUID? = nil
    var phase: GamePhase? = nil
    var ruleSet: RuleSet? = nil
    var pendingUnoCatch: PendingUnoCatch? = nil
    var pendingWildDraw4Challenge: PendingWildDraw4Challenge? = nil
    var pendingWildHadMatchingColor: Bool? = nil
    var roundWinnerID: UUID? = nil
    var gameWinnerID: UUID? = nil
    var lastRoundPoints: Int? = nil

    private enum CodingKeys: String, CodingKey {
        case players, deck, currentPlayerIndex, direction, pendingDrawStack, roundFinishOrder,
             drawnCardToPlayID, phase, ruleSet, pendingUnoCatch, pendingWildDraw4Challenge,
             pendingWildHadMatchingColor, roundWinnerID, gameWinnerID, lastRoundPoints
    }

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

extension SavedGame {
    var isValid: Bool {
        guard players.count >= 2, players.count <= 10 else { return false }
        guard players.indices.contains(currentPlayerIndex) else { return false }
        guard players.contains(where: { !$0.isAI }) else { return false }
        let ids = Set(players.map(\.id))
        guard ids.count == players.count, players.allSatisfy({ $0.totalScore >= 0 }),
              pendingDrawStack >= 0, pendingDrawStack <= 108,
              Set(roundFinishOrder).count == roundFinishOrder.count,
              Set(roundFinishOrder).isSubset(of: ids), let top = deck.topCard,
              top.effectiveColor != .wild else { return false }
        let resolvedPhase = phase ?? .playing
        let choosing: Card?
        if case .choosingColor(let card) = resolvedPhase { choosing = card } else { choosing = nil }
        let allCards = players.flatMap(\.hand) + deck.drawPile + deck.discardPile + (choosing.map { [$0] } ?? [])
        guard Set(allCards.map(\.id)).count == allCards.count,
              allCards.allSatisfy({ $0.isValid }) else { return false }
        switch resolvedPhase {
        case .playing, .dealing, .choosingColor:
            guard players.allSatisfy({ !$0.hand.isEmpty || roundFinishOrder.contains($0.id) ||
                (choosing != nil && $0.id == players[currentPlayerIndex].id) }),
                !roundFinishOrder.contains(players[currentPlayerIndex].id) else { return false }
        case .roundEnd, .gameEnd:
            guard let roundWinnerID, ids.contains(roundWinnerID) else { return false }
        case .menu: return false
        }
        if let gameWinnerID, !ids.contains(gameWinnerID) { return false }
        if resolvedPhase == .gameEnd && gameWinnerID == nil { return false }
        if let choosing, !choosing.value.isWild { return false }
        if let pendingWildDraw4Challenge {
            guard resolvedPhase == .playing,
                  players.indices.contains(pendingWildDraw4Challenge.playerIndex),
                  players.indices.contains(pendingWildDraw4Challenge.victimIndex),
                  pendingWildDraw4Challenge.victimIndex == currentPlayerIndex,
                  pendingWildDraw4Challenge.playerIndex != pendingWildDraw4Challenge.victimIndex,
                  top.value == .wildDrawFour else { return false }
        }
        if let pendingUnoCatch {
            guard ids.contains(pendingUnoCatch.playerID), players.indices.contains(pendingUnoCatch.blockingPlayerIndex) else { return false }
        }
        if let drawnCardToPlayID {
            guard resolvedPhase == .playing, pendingWildDraw4Challenge == nil,
                  !players[currentPlayerIndex].isAI,
                  players[currentPlayerIndex].hand.contains(where: { $0.id == drawnCardToPlayID }),
                  pendingDrawStack == 0 else { return false }
        }
        return true
    }
}

// The finish-order field predates the richer snapshots but was absent in early releases.
// Synthesized decoding does not apply stored-property defaults to missing non-optional keys.
extension SavedGame {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        players = try values.decode([Player].self, forKey: .players)
        deck = try values.decode(Deck.self, forKey: .deck)
        currentPlayerIndex = try values.decode(Int.self, forKey: .currentPlayerIndex)
        direction = try values.decode(TurnDirection.self, forKey: .direction)
        pendingDrawStack = try values.decodeIfPresent(Int.self, forKey: .pendingDrawStack) ?? 0
        roundFinishOrder = try values.decodeIfPresent([UUID].self, forKey: .roundFinishOrder) ?? []
        drawnCardToPlayID = try values.decodeIfPresent(UUID.self, forKey: .drawnCardToPlayID)
        phase = try values.decodeIfPresent(GamePhase.self, forKey: .phase)
        ruleSet = try values.decodeIfPresent(RuleSet.self, forKey: .ruleSet)
        pendingUnoCatch = try values.decodeIfPresent(PendingUnoCatch.self, forKey: .pendingUnoCatch)
        pendingWildDraw4Challenge = try values.decodeIfPresent(PendingWildDraw4Challenge.self, forKey: .pendingWildDraw4Challenge)
        pendingWildHadMatchingColor = try values.decodeIfPresent(Bool.self, forKey: .pendingWildHadMatchingColor)
        roundWinnerID = try values.decodeIfPresent(UUID.self, forKey: .roundWinnerID)
        gameWinnerID = try values.decodeIfPresent(UUID.self, forKey: .gameWinnerID)
        lastRoundPoints = try values.decodeIfPresent(Int.self, forKey: .lastRoundPoints)
    }
}
