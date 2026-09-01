import SwiftUI

struct PlayerHandView: View {
    let cards: [Card]
    let topCard: Card?
    let isMyTurn: Bool
    let namespace: Namespace.ID
    var justDrawnCardID: UUID? = nil
    let onPlay: (Card) -> Void

    @State private var pressedCardID: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: -18) {
                ForEach(cards) { card in
                    let playable = isMyTurn && topCard.map { card.canPlay(on: $0) } ?? false
                    let isPressed = pressedCardID == card.id
                    CardView(card: card, width: 78)
                        .matchedGeometryEffect(id: card.id, in: namespace, isSource: card.id != justDrawnCardID)
                        .offset(y: playable ? -14 : 0)
                        .scaleEffect(isPressed ? 0.92 : 1.0)
                        .opacity(isMyTurn ? (playable ? 1 : 0.55) : 0.85)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: playable)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    guard isMyTurn else { return }
                                    pressedCardID = card.id
                                }
                                .onEnded { _ in pressedCardID = nil }
                        )
                        .onTapGesture {
                            guard isMyTurn else { return }
                            onPlay(card)
                        }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint(playable ? L.t("game.cardPlayableHint") : L.t("game.cardUnplayableHint"))
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
    var cardWidth: CGFloat = 40
    var onCatchUno: (() -> Void)? = nil

    private var showsUnoCatch: Bool {
        onCatchUno != nil && player.hand.count == 1 && !player.hasCalledUno
    }

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
            HStack(spacing: -cardWidth * 0.85) {
                ForEach(player.hand) { card in
                    CardBackView(width: cardWidth)
                        .matchedGeometryEffect(id: card.id, in: namespace)
                }
            }
            .frame(height: cardWidth * 1.5)
            Text("\(player.hand.count)")
                .font(.caption2)
                .foregroundColor(.brandTextSecondary)

            if showsUnoCatch {
                Button(action: { onCatchUno?() }) {
                    Text(L.t("game.catchUno"))
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(Color.red))
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCurrentTurn ? Color.brandPrimary.opacity(0.18) : Color.clear)
        )
    }
}
