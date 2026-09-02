import Foundation

enum AIStrategy {
    /// Picks the best card for an AI hand to play against the current top card.
    /// Prefers action cards that attack opponents, then matching-color numbers (to keep
    /// future flexibility), and saves wilds for when no other option exists.
    static func chooseCard(hand: [Card], topCard: Card, opponentLowestCardCount: Int, difficulty: AIDifficulty = .normal, enforceWildDrawFourRestriction: Bool = false) -> Card? {
        let playable = hand.filter { $0.canPlay(on: topCard, hand: hand, enforceWildDrawFourRestriction: enforceWildDrawFourRestriction) }
        guard !playable.isEmpty else { return nil }

        switch difficulty {
        case .easy:
            return playable.randomElement()
        case .normal:
            return chooseCardNormal(playable: playable, opponentLowestCardCount: opponentLowestCardCount)
        case .hard:
            return chooseCardHard(hand: hand, playable: playable, opponentLowestCardCount: opponentLowestCardCount)
        }
    }

    /// Shared attack-priority logic used by both the normal and hard tiers: dump a Draw Two
    /// or Wild Draw Four when an opponent is at one card, then fall back to any disruptive
    /// action card (Skip, Reverse, Draw Two) before either tier applies its own tie-breaking.
    private static func attackCard(nonWild: [Card], wild: [Card], opponentLowestCardCount: Int) -> Card? {
        if opponentLowestCardCount == 1 {
            if let attack = nonWild.first(where: { $0.value == .drawTwo }) { return attack }
            if let attack = wild.first(where: { $0.value == .wildDrawFour }) { return attack }
        }
        return nonWild.first(where: { $0.value == .skip || $0.value == .reverse || $0.value == .drawTwo })
    }

    private static func chooseCardNormal(playable: [Card], opponentLowestCardCount: Int) -> Card? {
        let nonWild = playable.filter { !$0.value.isWild }
        let wild = playable.filter { $0.value.isWild }

        if let attack = attackCard(nonWild: nonWild, wild: wild, opponentLowestCardCount: opponentLowestCardCount) {
            return attack
        }

        if let number = nonWild.first(where: { if case .number = $0.value { return true }; return false }) {
            return number
        }

        if !nonWild.isEmpty { return nonWild.first }
        return wild.first
    }

    /// Hard AI additionally favors dumping the color it holds most in hand (to keep future
    /// flexibility) and holds onto wilds longer, only using them when no non-wild play exists.
    private static func chooseCardHard(hand: [Card], playable: [Card], opponentLowestCardCount: Int) -> Card? {
        let nonWild = playable.filter { !$0.value.isWild }
        let wild = playable.filter { $0.value.isWild }

        if let attack = attackCard(nonWild: nonWild, wild: wild, opponentLowestCardCount: opponentLowestCardCount) {
            return attack
        }

        if !nonWild.isEmpty {
            var counts: [CardColor: Int] = [:]
            for card in hand where !card.value.isWild { counts[card.color, default: 0] += 1 }
            let dominantColor = counts.max(by: { $0.value < $1.value })?.key
            if let dominant = dominantColor, let match = nonWild.first(where: { $0.color == dominant }) {
                return match
            }
            return nonWild.first
        }

        return wild.first
    }

    /// Chooses the color that appears most often in the remaining hand after the played card is removed.
    static func chooseColor(hand: [Card], excluding played: Card, difficulty: AIDifficulty = .normal) -> CardColor {
        if difficulty == .easy {
            return CardColor.playableColors.randomElement() ?? .red
        }
        var counts: [CardColor: Int] = [.red: 0, .yellow: 0, .green: 0, .blue: 0]
        for card in hand where card.id != played.id && !card.value.isWild {
            counts[card.color, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? .red
    }

    /// Picks a card to answer an active house-rule +2/+4 stack, or nil if the AI must draw the pile.
    /// Easy AI takes any stackable card at random; normal/hard prefer the biggest penalty (Wild Draw
    /// Four over Draw Two) to pass the largest possible pile on to the next player.
    static func chooseStackCard(hand: [Card], difficulty: AIDifficulty = .normal) -> Card? {
        let stackable = hand.filter { $0.value.drawPenaltyAmount != nil }
        guard !stackable.isEmpty else { return nil }

        if difficulty == .easy {
            return stackable.randomElement()
        }
        return stackable.max(by: { ($0.value.drawPenaltyAmount ?? 0) < ($1.value.drawPenaltyAmount ?? 0) })
    }

    static func shouldCallUnoImmediately(difficulty: AIDifficulty = .normal) -> Bool {
        switch difficulty {
        case .easy: return Double.random(in: 0...1) < 0.5
        case .normal: return Double.random(in: 0...1) < 0.85
        case .hard: return Double.random(in: 0...1) < 0.97
        }
    }
}
