import SwiftUI

struct PlayerHandView: View {
    let cards: [Card]
    let topCard: Card?
    let isMyTurn: Bool
    let namespace: Namespace.ID
    let onPlay: (Card) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: -18) {
                ForEach(cards) { card in
                    let playable = isMyTurn && topCard.map { card.canPlay(on: $0) } ?? false
                    CardView(card: card, width: 78)
                        .matchedGeometryEffect(id: card.id, in: namespace)
                        .offset(y: playable ? -14 : 0)
                        .opacity(isMyTurn ? (playable ? 1 : 0.55) : 0.85)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: playable)
                        .onTapGesture {
                            guard isMyTurn else { return }
                            onPlay(card)
                        }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }
}

struct OpponentHandView: View {
    let player: Player
    let namespace: Namespace.ID
    let isCurrentTurn: Bool
    let isThinking: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text(player.name)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.brandTextPrimary)
                if isThinking && isCurrentTurn {
                    Text(L.t("game.thinking"))
                        .font(.caption2)
                        .foregroundColor(.brandTextSecondary)
                }
                if player.hasCalledUno && player.hand.count == 1 {
                    Text(L.t("game.uno"))
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.brandSecondary)
                }
            }
            HStack(spacing: -34) {
                ForEach(player.hand) { card in
                    CardBackView(width: 40)
                        .matchedGeometryEffect(id: card.id, in: namespace)
                }
            }
            .frame(height: 60)
            Text("\(player.hand.count)")
                .font(.caption2)
                .foregroundColor(.brandTextSecondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCurrentTurn ? Color.brandPrimary.opacity(0.18) : Color.clear)
        )
    }
}
