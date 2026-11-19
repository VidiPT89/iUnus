import SwiftUI

struct PlayerHandView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    let cards: [Card]
    var cardWidth: CGFloat = 78
    let namespace: Namespace.ID
    var justDrawnCardID: UUID? = nil
    let canPlay: (Card) -> Bool
    let onPlay: (Card) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(cards) { card in
                        let playable = canPlay(card)
                        Button { onPlay(card) } label: {
                            CardView(card: card, width: cardWidth)
                                .matchedGeometryEffect(id: card.id, in: namespace, isSource: card.id != justDrawnCardID)
                                .overlay(alignment: .topTrailing) {
                                    if playable {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white, Color.brandPrimary)
                                            .font(.title3)
                                            .offset(x: 4, y: -6)
                                    }
                                }
                                .opacity(playable ? 1 : 0.65)
                        }
                        .buttonStyle(.plain)
                        .disabled(!playable)
                        .id(card.id)
                        .accessibilityLabel(card.accessibilityLabel)
                        .accessibilityHint(playable ? L.t("game.cardPlayableHint") : L.t("game.cardUnplayableHint"))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .frame(height: cardWidth * 1.5 + 32)
            .onChange(of: justDrawnCardID) { id in
                if let id { proxy.scrollTo(id, anchor: .center) }
            }
        }
    }
}

struct OpponentHandView: View {
    @ObservedObject private var localization = LocalizationManager.shared
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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
                ForEach(Array(player.hand.prefix(7))) { card in
                    CardBackView(width: cardWidth)
                        .matchedGeometryEffect(id: card.id, in: namespace)
                }
            }
            .frame(height: cardWidth * 1.5)
            Text(String(format: L.t("game.cardCount"), player.hand.count))
                .font(.caption.weight(.bold))
                .foregroundColor(.brandTextSecondary)

            if showsUnoCatch {
                Button(action: { onCatchUno?() }) {
                    Text(L.t("game.catchUno"))
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .frame(minHeight: 44)
                        .background(Capsule().fill(Color.red))
                }
            }
        }
        .frame(minWidth: 76)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCurrentTurn ? Color.brandPrimary.opacity(0.18) : Color.brandSurface.opacity(0.8))
        )
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(isCurrentTurn ? Color.brandPrimary : Color.clear, lineWidth: 2))
    }
}
