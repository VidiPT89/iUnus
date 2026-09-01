import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @Namespace private var cardSpace
    @State private var dealt = false
    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()

            VStack(spacing: 12) {
                TopBarView(
                    turnText: turnText,
                    isHumanTurn: isHumanTurn,
                    canCallUno: canCallUno,
                    onUnoTapped: { if let id = viewModel.humanPlayer?.id { viewModel.callUno(playerID: id) } },
                    onQuit: { viewModel.returnToMenu() }
                )
                .padding(.top, 8)

                opponentsRow

                Spacer(minLength: 4)

                pileArea

                Spacer(minLength: 4)

                if let human = viewModel.humanPlayer {
                    PlayerHandView(
                        cards: human.hand,
                        topCard: viewModel.topCard,
                        isMyTurn: isHumanTurn && viewModel.phase == .playing,
                        namespace: cardSpace,
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
        }
    }

    private var opponentsRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.players.filter { $0.isAI }) { player in
                OpponentHandView(
                    player: player,
                    namespace: cardSpace,
                    isCurrentTurn: viewModel.currentPlayer?.id == player.id,
                    isThinking: viewModel.isAIThinking
                )
            }
        }
        .padding(.horizontal)
    }

    private var pileArea: some View {
        HStack(spacing: 36) {
            Button {
                viewModel.humanDraw()
            } label: {
                CardBackView(width: 78)
                    .overlay(
                        Text(L.t("game.draw"))
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Capsule().fill(Color.black.opacity(0.5)))
                            .offset(y: 50)
                    )
            }
            .disabled(!(isHumanTurn && viewModel.phase == .playing))

            if let top = viewModel.topCard {
                CardView(card: top, width: 84)
                    .id(top.id)
                    .matchedGeometryEffect(id: top.id, in: cardSpace)
                    .rotationEffect(.degrees(Double.random(in: -6...6)))
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.4).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .animation(.spring(response: 0.45, dampingFraction: 0.75), value: top.id)
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
