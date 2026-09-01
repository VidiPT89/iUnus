import SwiftUI

struct GameEndView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showConfetti = false

    private var winnerName: String {
        viewModel.players.first(where: { $0.id == viewModel.gameWinnerID })?.name ?? ""
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.brandBackground, .brandPrimary.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

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

                if let winnerScore = viewModel.players.first(where: { $0.id == viewModel.gameWinnerID })?.totalScore {
                    CountUpText(value: winnerScore, duration: 1.4)
                        .font(.title.weight(.heavy))
                        .foregroundColor(.brandSecondary)
                }

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
        .onAppear { showConfetti = true }
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let xFraction: CGFloat
    let delay: Double
    let duration: Double
    let rotation: Double
    let size: CGFloat
}

/// Pure-SwiftUI confetti burst: small colored shapes fall from above the screen with
/// randomized timing, rotation, and horizontal position, using TimelineView to drive motion.
struct ConfettiView: View {
    private let pieces: [ConfettiPiece] = (0..<40).map { _ in
        ConfettiPiece(
            color: [Color.red, .yellow, .green, .blue, .brandPrimary, .brandSecondary].randomElement() ?? .red,
            xFraction: CGFloat.random(in: 0...1),
            delay: Double.random(in: 0...0.6),
            duration: Double.random(in: 1.8...3.0),
            rotation: Double.random(in: 180...720),
            size: CGFloat.random(in: 6...12)
        )
    }
    private let startDate = Date()

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                ForEach(pieces) { piece in
                    let t = max(0, elapsed - piece.delay)
                    let progress = min(t / piece.duration, 1)
                    let y = -40 + progress * (proxy.size.height + 80)
                    let opacity: Double = progress >= 1 ? 0 : 1
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 0.4)
                        .rotationEffect(.degrees(piece.rotation * progress))
                        .position(x: proxy.size.width * piece.xFraction, y: y)
                        .opacity(opacity)
                }
            }
        }
    }
}
