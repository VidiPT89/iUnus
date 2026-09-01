import Foundation

struct Deck {
    private(set) var drawPile: [Card] = []
    private(set) var discardPile: [Card] = []

    static func freshDeck() -> [Card] {
        var cards: [Card] = []
        for color in CardColor.playableColors {
            cards.append(Card(color: color, value: .number(0)))
            for n in 1...9 {
                cards.append(Card(color: color, value: .number(n)))
                cards.append(Card(color: color, value: .number(n)))
            }
            for _ in 0..<2 {
                cards.append(Card(color: color, value: .skip))
                cards.append(Card(color: color, value: .reverse))
                cards.append(Card(color: color, value: .drawTwo))
            }
        }
        for _ in 0..<4 {
            cards.append(Card(color: .wild, value: .wild))
            cards.append(Card(color: .wild, value: .wildDrawFour))
        }
        return cards
    }

    init() {
        drawPile = Deck.freshDeck().shuffled()
    }

    mutating func draw() -> Card? {
        if drawPile.isEmpty { reshuffleFromDiscard() }
        guard !drawPile.isEmpty else { return nil }
        return drawPile.removeFirst()
    }

    mutating func discard(_ card: Card) {
        discardPile.append(card)
    }

    mutating func startDiscard(with card: Card) {
        discardPile = [card]
    }

    var topCard: Card? { discardPile.last }

    mutating func reshuffleFromDiscard() {
        guard discardPile.count > 1 else { return }
        let top = discardPile.removeLast()
        var rest = discardPile
        rest = rest.map { card -> Card in
            var c = card
            if c.value.isWild { c.chosenColor = nil }
            return c
        }
        drawPile = rest.shuffled()
        discardPile = [top]
    }
}
