import SwiftUI

struct RoundEndView: View {
    @ObservedObject var viewModel: GameViewModel

    private var winnerName: String {
        viewModel.players.first(where: { $0.id == viewModel.roundWinnerID })?.name ?? ""
    }

    /// Full finishing order for a House Rules "last player standing" round: everyone recorded
    /// in `roundFinishOrder`, in the order they emptied their hand, followed by whoever was left
    /// still holding cards. Empty when the round ended the Official way (first empty hand wins).
    private var finishOrderNames: [String] {
        guard !viewModel.roundFinishOrder.isEmpty else { return [] }
        let byID = Dictionary(uniqueKeysWithValues: viewModel.players.map { ($0.id, $0.name) })
        var names = viewModel.roundFinishOrder.compactMap { byID[$0] }
        let lastPlayer = viewModel.players.first { !viewModel.roundFinishOrder.contains($0.id) }
        if let lastPlayer { names.append(lastPlayer.name) }
        return names
    }

    private func placeLabel(_ index: Int, total: Int) -> String {
        if index == total - 1 { return L.t("roundEnd.place.last") }
        switch index {
        case 0: return L.t("roundEnd.place.1")
        case 1: return L.t("roundEnd.place.2")
        case 2: return L.t("roundEnd.place.3")
        default: return String(format: L.t("roundEnd.place.n"), index + 1)
        }
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

                if !finishOrderNames.isEmpty {
                    VStack(spacing: 8) {
                        Text(L.t("roundEnd.finishOrder"))
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.brandTextSecondary)
                        ForEach(Array(finishOrderNames.enumerated()), id: \.offset) { index, name in
                            HStack {
                                Text(placeLabel(index, total: finishOrderNames.count))
                                    .fontWeight(.semibold)
                                Text(name)
                                Spacer()
                            }
                            .font(.subheadline)
                            .foregroundColor(.brandTextPrimary)
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.brandSurface))
                    .padding(.horizontal, 32)
                }

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
