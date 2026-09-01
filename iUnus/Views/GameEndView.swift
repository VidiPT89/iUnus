import SwiftUI

struct GameEndView: View {
    @ObservedObject var viewModel: GameViewModel

    private var winnerName: String {
        viewModel.players.first(where: { $0.id == viewModel.gameWinnerID })?.name ?? ""
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.brandBackground, .brandPrimary.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "crown.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.brandSecondary)

                Text(L.t("gameEnd.title"))
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(.brandPrimary)

                Text(String(format: L.t("gameEnd.winner"), winnerName))
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.brandTextPrimary)

                Spacer()

                VStack(spacing: 14) {
                    Button {
                        viewModel.startNewGame(opponentCount: max(1, viewModel.players.filter { $0.isAI }.count))
                    } label: {
                        Text(L.t("gameEnd.newGame"))
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: 260)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color.brandPrimary))
                    }

                    Button {
                        viewModel.returnToMenu()
                    } label: {
                        Text(L.t("gameEnd.backToMenu"))
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.brandTextSecondary)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}
