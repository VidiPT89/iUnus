import SwiftUI

struct GameView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject var viewModel: GameViewModel
    @Namespace private var cardSpace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dealtCardCount = 0
    @State private var wildFlourishScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 700
            ZStack {
                Color.brandBackground.ignoresSafeArea()
                RadialGradient(colors: [Color.brandPrimary.opacity(0.14), .clear], center: .center, startRadius: 20, endRadius: 380)
                    .ignoresSafeArea()
                Ellipse().stroke(Color.brandPrimary.opacity(0.09), lineWidth: 2)
                    .frame(height: 300).padding(.horizontal, 20)
                    .allowsHitTesting(false)

                ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    TopBarView(
                        turnText: turnText,
                        isHumanTurn: isHumanTurn,
                        canCallUno: canCallUno,
                        direction: viewModel.direction,
                        pendingDrawStack: viewModel.pendingDrawStack,
                        onUnoTapped: { if let id = viewModel.localViewPlayer?.id { viewModel.callUno(playerID: id) } },
                        onQuit: { viewModel.quitToMenu() }
                    )
                    .disabled(viewModel.isOnlineUpdatePending)
                    .padding(.top, 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.pendingDrawStack)

                    opponentsRow(compact: compact)

                    Spacer(minLength: 0)

                    pileArea(compact: compact)

                    Spacer(minLength: 0)

                    if let human = viewModel.localViewPlayer {
                        handGuidance
                        PlayerHandView(
                            cards: human.hand,
                            cardWidth: compact ? 64 : 78,
                            namespace: cardSpace,
                            justDrawnCardID: viewModel.justDrawnCard?.id,
                            canPlay: viewModel.canLocalPlayerPlay,
                            onPlay: { viewModel.humanPlay($0) }
                        )
                    }
                }
                .frame(maxWidth: 760)
                .frame(minHeight: geometry.size.height)
                .frame(maxWidth: .infinity)
                }
            }
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
                    .presentationDetents([.medium, .large])
                    .interactiveDismissDisabled(true)
            }
            .sheet(isPresented: wildDraw4ChallengeSheetBinding) {
                if let pending = viewModel.wildDraw4ChallengeForLocalHuman {
                    WildDraw4ChallengeSheet(
                        offenderName: viewModel.players.indices.contains(pending.playerIndex) ? viewModel.players[pending.playerIndex].name : "",
                        onChallenge: { viewModel.resolveWildDraw4Challenge(challenge: true) },
                        onAccept: { viewModel.resolveWildDraw4Challenge(challenge: false) }
                    )
                    .presentationDetents([.medium, .large])
                    .interactiveDismissDisabled(true)
                }
            }
            .overlay {
                if viewModel.phase == .dealing && !reduceMotion {
                    dealingOverlay
                }
            }
            .onChange(of: viewModel.phase) { phase in
                guard phase == .dealing else { return }
                runDealingAnimation()
            }
            .onAppear {
                if viewModel.phase == .dealing && !reduceMotion { runDealingAnimation() }
            }
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
        guard !reduceMotion else { return }
        dealtCardCount = 0
        let totalCards = max(viewModel.players.count, 1) * 7
        let stepDelay = totalCards > 0 ? min(1.2 / Double(totalCards), 0.09) : 0.05
        for i in 0...totalCards {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDelay * Double(i)) {
                dealtCardCount = i
            }
        }
    }

    private func opponentsRow(compact: Bool) -> some View {
        let opponents = viewModel.opponentPlayers
        let baseCardWidth: CGFloat = compact ? 26 : 40
        let minSpacing: CGFloat = 8

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: minSpacing) {
                opponentViews(opponents, cardWidth: baseCardWidth)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .frame(height: (compact ? 100 : 142) + (viewModel.pendingUnoCatch != nil ? 44 : 0))
    }

    private func opponentViews(_ opponents: [Player], cardWidth: CGFloat) -> some View {
        ForEach(opponents) { player in
            OpponentHandView(
                player: player,
                namespace: cardSpace,
                isCurrentTurn: viewModel.currentPlayer?.id == player.id,
                isThinking: viewModel.isAIThinking,
                cardWidth: cardWidth,
                onCatchUno: !viewModel.isOnlineUpdatePending && (viewModel.mode == .local || isHumanTurn) && viewModel.pendingUnoCatch?.playerID == player.id
                    ? { viewModel.catchFailureToCallUno() }
                    : nil
            )
        }
    }

    private func pileArea(compact: Bool) -> some View {
        HStack(alignment: .top, spacing: 40) {
            VStack(spacing: 8) {
                Button {
                    viewModel.humanDraw()
                } label: {
                    CardBackView(width: compact ? 62 : 78)
                }
                .disabled(!(isHumanTurn && viewModel.phase == .playing) || viewModel.drawnCardToPlayID != nil || viewModel.isOnlineUpdatePending)
                .opacity(isHumanTurn && viewModel.phase == .playing ? 1 : 0.6)
                .accessibilityLabel(L.t("game.drawPile"))
                .accessibilityHint(L.t("game.drawPileHint"))
                .overlay {
                    if let drawn = viewModel.justDrawnCard, viewModel.localViewPlayer?.hand.contains(where: { $0.id == drawn.id }) == true {
                        CardView(card: drawn, width: compact ? 62 : 78)
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
                    CardView(card: top, width: compact ? 68 : 84)
                        .id(top.id)
                        .matchedGeometryEffect(id: top.id, in: cardSpace)
                        .rotationEffect(.degrees(Double(top.id.uuid.0 % 9) - 4))
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

    private var handGuidance: some View {
        VStack(spacing: 10) {
            if let top = viewModel.topCard {
                Label(L.t("color." + top.effectiveColor.rawValue), systemImage: "circle.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.brandTextPrimary)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(top.effectiveColor.displayColor.opacity(0.18)))
                    .accessibilityLabel(L.t("game.activeColor") + ": " + L.t("color." + top.effectiveColor.rawValue))
            }
            if viewModel.drawnCardToPlayID != nil && isHumanTurn {
                Text(L.t("game.drawnChoice")).font(.caption)
                Button(L.t("game.pass")) { viewModel.humanPassAfterDraw() }
                    .buttonStyle(.borderedProminent).tint(.brandPrimary)
                    .foregroundColor(.black)
            } else {
                Text(isHumanTurn ? L.t(viewModel.pendingDrawStack > 0 ? "game.stackGuidance" : ((viewModel.localViewPlayer?.hand.contains(where: viewModel.canLocalPlayerPlay) ?? false) ? "game.handGuidance" : "game.mustDraw")) : turnText)
                    .font(.subheadline)
            }
        }
        .foregroundColor(.brandTextSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
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

    private var wildDraw4ChallengeSheetBinding: Binding<Bool> {
        Binding(get: { viewModel.wildDraw4ChallengeForLocalHuman != nil }, set: { _ in })
    }

    private var isHumanTurn: Bool { viewModel.isLocalTurn }

    private var canCallUno: Bool {
        guard !viewModel.isOnlineUpdatePending, viewModel.mode == .local || isHumanTurn, let human = viewModel.localViewPlayer else { return false }
        return human.hand.count == 1 && !human.hasCalledUno
    }

    private var turnText: String {
        guard let current = viewModel.currentPlayer else { return "" }
        return viewModel.isLocalTurn ? L.t("game.yourTurn") : String(format: L.t("game.aiTurn"), current.name)
    }
}
