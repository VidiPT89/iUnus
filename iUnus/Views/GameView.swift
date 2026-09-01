import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @Namespace private var cardSpace
    @State private var dealtCardCount = 0
    @State private var wildFlourishScale: CGFloat = 1.0
    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                TopBarView(
                    turnText: turnText,
                    isHumanTurn: isHumanTurn,
                    canCallUno: canCallUno,
                    direction: viewModel.direction,
                    pendingDrawStack: viewModel.pendingDrawStack,
                    onUnoTapped: { if let id = viewModel.humanPlayer?.id { viewModel.callUno(playerID: id) } },
                    onQuit: { viewModel.returnToMenu() }
                )
                .padding(.top, 8)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.pendingDrawStack)

                opponentsRow

                Spacer(minLength: 12)

                pileArea

                Spacer(minLength: 12)

                if let human = viewModel.humanPlayer {
                    PlayerHandView(
                        cards: human.hand,
                        topCard: viewModel.topCard,
                        isMyTurn: isHumanTurn && viewModel.phase == .playing,
                        namespace: cardSpace,
                        justDrawnCardID: viewModel.justDrawnCard?.id,
                        onPlay: { viewModel.humanPlay($0) }
                    )
                }
            }
        }
        .onReceive(timer) { _ in viewModel.checkUnoTimeout() }
        .overlay(alignment: .top) {
            if let toast = viewModel.toastMessage {
                Text(toast)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.85)))
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.toastMessage)
        .sheet(isPresented: colorSheetBinding) {
            ColorPickerSheet { color in viewModel.chooseWildColor(color) }
                .presentationDetents([.height(280)])
                .interactiveDismissDisabled(true)
        }
        .overlay {
            if viewModel.phase == .dealing {
                dealingOverlay
            }
        }
        .onChange(of: viewModel.phase) { phase in
            guard phase == .dealing else { return }
            runDealingAnimation()
        }
        .onAppear {
            if viewModel.phase == .dealing { runDealingAnimation() }
        }
    }

    private var dealingOverlay: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let playerCount = max(viewModel.players.count, 1)
            let totalCards = playerCount * 7
            let targets = dealTargets(in: proxy.size, playerCount: playerCount)

            ZStack {
                ForEach(0..<totalCards, id: \.self) { index in
                    let target = targets[index % playerCount]
                    let revealed = index < dealtCardCount
                    CardBackView(width: 34)
                        .position(revealed ? target : center)
                        .opacity(revealed ? 1 : 0.001)
                        .animation(.easeOut(duration: 0.18), value: dealtCardCount)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func dealTargets(in size: CGSize, playerCount: Int) -> [CGPoint] {
        var points: [CGPoint] = [CGPoint(x: size.width / 2, y: size.height - 90)]
        let opponentCount = playerCount - 1
        if opponentCount > 0 {
            for i in 0..<opponentCount {
                let fraction = (CGFloat(i) + 1) / CGFloat(opponentCount + 1)
                points.append(CGPoint(x: size.width * fraction, y: 130))
            }
        }
        return points
    }

    private func runDealingAnimation() {
        dealtCardCount = 0
        let totalCards = max(viewModel.players.count, 1) * 7
        let stepDelay = totalCards > 0 ? min(1.2 / Double(totalCards), 0.09) : 0.05
        for i in 0...totalCards {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDelay * Double(i)) {
                dealtCardCount = i
            }
        }
    }

    private var opponentsRow: some View {
        let opponents = viewModel.players.filter { $0.isAI }
        return GeometryReader { proxy in
            let baseCardWidth: CGFloat = 40
            let minSpacing: CGFloat = 8
            let availableWidth = proxy.size.width - 32
            let neededWidth = CGFloat(opponents.count) * baseCardWidth + CGFloat(max(opponents.count - 1, 0)) * minSpacing
            let scale = neededWidth > availableWidth && neededWidth > 0 ? max(availableWidth / neededWidth, 0.55) : 1.0

            HStack(spacing: minSpacing * scale) {
                ForEach(opponents) { player in
                    OpponentHandView(
                        player: player,
                        namespace: cardSpace,
                        isCurrentTurn: viewModel.currentPlayer?.id == player.id,
                        isThinking: viewModel.isAIThinking,
                        cardWidth: baseCardWidth * scale,
                        onCatchUno: viewModel.pendingUnoCatch?.playerID == player.id
                            ? { viewModel.catchFailureToCallUno() }
                            : nil
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
        .frame(height: 100)
    }

    private var pileArea: some View {
        HStack(alignment: .top, spacing: 40) {
            VStack(spacing: 8) {
                Button {
                    viewModel.humanDraw()
                } label: {
                    CardBackView(width: 78)
                }
                .disabled(!(isHumanTurn && viewModel.phase == .playing))
                .opacity(isHumanTurn && viewModel.phase == .playing ? 1 : 0.6)
                .accessibilityLabel(L.t("game.drawPile"))
                .accessibilityHint(L.t("game.drawPileHint"))
                .overlay {
                    if let drawn = viewModel.justDrawnCard, viewModel.humanPlayer?.hand.contains(where: { $0.id == drawn.id }) == true {
                        CardView(card: drawn, width: 78)
                            .matchedGeometryEffect(id: drawn.id, in: cardSpace, isSource: true)
                            .allowsHitTesting(false)
                            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: viewModel.justDrawnCard?.id)
                    }
                }

                Text(L.t("game.draw"))
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 10).padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
            }

            if let top = viewModel.topCard {
                VStack(spacing: 8) {
                    CardView(card: top, width: 84)
                        .id(top.id)
                        .matchedGeometryEffect(id: top.id, in: cardSpace)
                        .rotationEffect(.degrees(Double.random(in: -6...6)))
                        .scaleEffect(wildFlourishScale)
                        .shadow(color: top.effectiveColor.displayColor.opacity(wildFlourishScale > 1.0 ? 0.7 : 0), radius: 12)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.4).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: top.id)
                        .onChange(of: top.chosenColor) { _ in
                            wildFlourishScale = 1.25
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                                wildFlourishScale = 1.0
                            }
                        }
                }
            }
        }
    }

    private var colorSheetBinding: Binding<Bool> {
        Binding(
            get: {
                if case .choosingColor = viewModel.phase { return true }
                return false
            },
            set: { _ in }
        )
    }

    private var isHumanTurn: Bool { viewModel.currentPlayer?.isAI == false }

    private var canCallUno: Bool {
        guard let human = viewModel.humanPlayer else { return false }
        return human.hand.count == 1 && !human.hasCalledUno
    }

    private var turnText: String {
        guard let current = viewModel.currentPlayer else { return "" }
        return current.isAI ? String(format: L.t("game.aiTurn"), current.name) : L.t("game.yourTurn")
    }
}
