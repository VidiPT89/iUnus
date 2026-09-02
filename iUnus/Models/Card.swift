import Foundation

struct Card: Identifiable, Equatable, Codable, Hashable {
    let id: UUID
    var color: CardColor
    let value: CardValue
    /// Only set for wild cards once a player chooses a color; the base `color` stays `.wild`.
    var chosenColor: CardColor?

    init(id: UUID = UUID(), color: CardColor, value: CardValue, chosenColor: CardColor? = nil) {
        self.id = id
        self.color = color
        self.value = value
        self.chosenColor = chosenColor
    }

    var effectiveColor: CardColor { chosenColor ?? color }

    var accessibilityLabel: String {
        let colorKey: String
        switch effectiveColor {
        case .red: colorKey = "color.red"
        case .yellow: colorKey = "color.yellow"
        case .green: colorKey = "color.green"
        case .blue: colorKey = "color.blue"
        case .wild: colorKey = "color.wild"
        }
        let valueKey: String
        switch value {
        case .number(let n): return String(format: L.t("card.label"), L.t(colorKey), String(n))
        case .skip: valueKey = "card.value.skip"
        case .reverse: valueKey = "card.value.reverse"
        case .drawTwo: valueKey = "card.value.drawTwo"
        case .wild: return L.t("card.value.wild")
        case .wildDrawFour: return L.t("card.value.wildDrawFour")
        }
        return String(format: L.t("card.label"), L.t(colorKey), L.t(valueKey))
    }

    /// `hand` and `enforceWildDrawFourRestriction` implement the official rule that a Wild
    /// Draw Four may only be played when the player holds no card matching the active color —
    /// house rules waive this, so callers there can omit both and get the old behavior.
    func canPlay(on topCard: Card, hand: [Card] = [], enforceWildDrawFourRestriction: Bool = false) -> Bool {
        if value == .wildDrawFour && enforceWildDrawFourRestriction {
            let hasMatchingColorCard = hand.contains { !$0.value.isWild && $0.color == topCard.effectiveColor }
            if hasMatchingColorCard { return false }
        }
        if value.isWild { return true }
        if effectiveColor == topCard.effectiveColor { return true }
        if value == topCard.value { return true }
        return false
    }

    static func == (lhs: Card, rhs: Card) -> Bool { lhs.id == rhs.id }

    /// Stable sort key: color group first (wilds last), then value within color.
    private var sortKey: (Int, Int) {
        let colorOrder: [CardColor: Int] = [.red: 0, .yellow: 1, .green: 2, .blue: 3, .wild: 4]
        let colorRank = colorOrder[color] ?? 4
        let valueRank: Int
        switch value {
        case .number(let n): valueRank = n
        case .skip: valueRank = 10
        case .reverse: valueRank = 11
        case .drawTwo: valueRank = 12
        case .wild: valueRank = 13
        case .wildDrawFour: valueRank = 14
        }
        return (colorRank, valueRank)
    }

    static func displayOrder(_ lhs: Card, _ rhs: Card) -> Bool {
        let l = lhs.sortKey
        let r = rhs.sortKey
        return l.0 != r.0 ? l.0 < r.0 : l.1 < r.1
    }
}

extension Array where Element == Card {
    mutating func sortForDisplay() {
        sort(by: Card.displayOrder)
    }
}
