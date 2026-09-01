import SwiftUI

struct RoundEndView: View {
    @ObservedObject var viewModel: GameViewModel

    private var winnerName: String {
        viewModel.players.first(where: { $0.id == viewModel.roundWinnerID })?.name ?? ""
    }

    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text(L.t("roundEnd.title"))
                    .font(.largeTitle.weight(.black))
                    .foregroundColor(.brandPrimary)

                Text(String(format: L.t("roundEnd.winner"), winnerName))
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.brandTextPrimary)

                CountUpText(format: L.t("roundEnd.pointsEarned"), value: viewModel.lastRoundPoints)
                    .font(.headline)
                    .foregroundColor(.brandSecondary)

                VStack(spacing: 8) {
                    Text(L.t("roundEnd.scores"))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.brandTextSecondary)
                    ForEach(viewModel.players) { player in
                        HStack {
                            Text(player.name)
                            Spacer()
                            CountUpText(value: player.totalScore)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.brandTextPrimary)
                        .padding(.horizontal, 24)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.brandSurface))
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    viewModel.continueAfterRound()
                } label: {
                    Text(L.t("roundEnd.continue"))
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: 260)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color.brandPrimary))
                }
                .padding(.bottom, 40)
            }
        }
    }
}

/// Animates a displayed integer counting up from 0 to `value` over a fixed duration.
struct CountUpText: View {
    var format: String? = nil
    let value: Int
    var duration: TimeInterval = 1.0

    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)
            let progress = min(max(elapsed / duration, 0), 1)
            let eased = 1 - pow(1 - progress, 3)
            let displayed = Int((Double(value) * eased).rounded())
            Text(format.map { String(format: $0, displayed) } ?? "\(displayed)")
                .monospacedDigit()
        }
        .onAppear { startDate = Date() }
    }
}
