import SwiftUI

struct TopBarView: View {
    let turnText: String
    let isHumanTurn: Bool
    let canCallUno: Bool
    let direction: TurnDirection
    let onUnoTapped: () -> Void
    let onQuit: () -> Void

    var body: some View {
        HStack {
            Button(action: onQuit) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.brandTextSecondary)
            }
            .accessibilityLabel(L.t("game.quit"))
            .accessibilityHint(L.t("game.quitHint"))

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: direction == .clockwise ? "arrow.clockwise" : "arrow.counterclockwise")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.brandTextSecondary)
                    .rotation3DEffect(.degrees(direction == .clockwise ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: direction)
                    .accessibilityHidden(true)

                Text(turnText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isHumanTurn ? .brandPrimary : .brandTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.brandSurface))
            .accessibilityElement(children: .combine)

            Spacer()

            Button(action: onUnoTapped) {
                Text(L.t("game.uno"))
                    .font(.headline.weight(.heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(canCallUno ? Color.brandSecondary : Color.brandTextSecondary.opacity(0.35)))
            }
            .disabled(!canCallUno)
            .scaleEffect(canCallUno ? 1.0 : 0.94)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: canCallUno)
            .accessibilityLabel(L.t("game.uno"))
            .accessibilityHint(L.t("game.unoHint"))
        }
        .padding(.horizontal)
    }
}
