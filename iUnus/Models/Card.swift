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

    func canPlay(on topCard: Card) -> Bool {
        if value.isWild { return true }
        if effectiveColor == topCard.effectiveColor { return true }
        if value == topCard.value { return true }
        return false
    }

    static func == (lhs: Card, rhs: Card) -> Bool { lhs.id == rhs.id }
}
