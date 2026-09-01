import SwiftUI

struct TopBarView: View {
    let turnText: String
    let isHumanTurn: Bool
    let canCallUno: Bool
    let onUnoTapped: () -> Void
    let onQuit: () -> Void

    var body: some View {
        HStack {
            Button(action: onQuit) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.brandTextSecondary)
            }

            Spacer()

            Text(turnText)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(isHumanTurn ? .brandPrimary : .brandTextPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.brandSurface))

            Spacer()

            Button(action: onUnoTapped) {
                Text(L.t("game.uno"))
                    .font(.headline.weight(.heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(canCallUno ? Color.brandSecondary : Color.gray.opacity(0.4)))
            }
            .disabled(!canCallUno)
            .scaleEffect(canCallUno ? 1.0 : 0.94)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: canCallUno)
        }
        .padding(.horizontal)
    }
}
