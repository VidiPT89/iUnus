import Foundation
import Combine
import UIKit

final class GameViewModel: ObservableObject {
    @Published private(set) var players: [Player] = []
    @Published private(set) var deck = Deck()
    @Published private(set) var currentPlayerIndex: Int = 0
    @Published private(set) var direction: TurnDirection = .clockwise
    @Published var phase: GamePhase = .menu
    @Published private(set) var lastMove: LastMove?
    @Published private(set) var pendingUnoCatch: PendingUnoCatch?
    @Published var toastMessage: String?
    @Published private(set) var roundWinnerID: UUID?
    @Published private(set) var gameWinnerID: UUID?
    @Published private(set) var lastRoundPoints: Int = 0
    @Published private(set) var isAIThinking: Bool = false

    static let targetScore = 500
    private let unoCatchWindow: TimeInterval = 3.0
    private var toastWorkItem: DispatchWorkItem?

    var topCard: Card? { deck.topCard }
    var currentPlayer: Player? { players.indices.contains(currentPlayerIndex) ? players[currentPlayerIndex] : nil }
    var humanPlayer: Player? { players.first(where: { !$0.isAI }) }

    func startNewGame(opponentCount: Int) {
        let clamped = max(1, min(3, opponentCount))
        var newPlayers = [Player(name: L.t("player.you"), kind: .human)]
        for i in 1...clamped {
            newPlayers.append(Player(name: String(format: L.t("player.opponent"), i), kind: .ai))
        }
        players = newPlayers
        gameWinnerID = nil
        startNewRound()
    }

    func startNewRound() {
        deck = Deck()
        direction = .clockwise
        lastMove = nil
        pendingUnoCatch = nil
        roundWinnerID = nil
        for i in players.indices {
            players[i].hand = []
            players[i].hasCalledUno = false
        }
        phase = .dealing

        var mutableDeck = deck
        for _ in 0..<7 {
            for i in players.indices {
                if let card = mutableDeck.draw() {
                    players[i].hand.append(card)
                }
            }
        }
        var starter = mutableDeck.draw()
        while let s = starter, s.value.isWild {
            mutableDeck.discard(s)
            starter = mutableDeck.draw()
        }
        if let starter { mutableDeck.startDiscard(with: starter) }
        deck = mutableDeck
        currentPlayerIndex = 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            guard let self else { return }
            self.phase = .playing
            self.advanceIfAITurn()
        }
    }

    // MARK: - Playing cards

    func humanPlay(_ card: Card) {
        guard let player = currentPlayer, !player.isAI, phase == .playing else { return }
        attemptPlay(card, playerIndex: currentPlayerIndex)
    }

    private func attemptPlay(_ card: Card, playerIndex: Int) {
        guard let top = topCard else { return }
        guard let handIndex = players[playerIndex].hand.firstIndex(where: { $0.id == card.id }) else { return }
        guard card.canPlay(on: top) else {
            if !players[playerIndex].isAI { hapticError(); showToast(L.t("game.invalidMove")) }
            return
        }

        var playedCard = players[playerIndex].hand.remove(at: handIndex)
        hapticPlay()
        lastMove = LastMove(card: playedCard, playerID: players[playerIndex].id)

        if playedCard.value.isWild {
            if players[playerIndex].isAI {
                let color = AIStrategy.chooseColor(hand: players[playerIndex].hand, excluding: playedCard)
                playedCard.chosenColor = color
                finalizePlay(playedCard, playerIndex: playerIndex)
            } else {
                phase = .choosingColor(pendingCard: playedCard)
                pendingWildPlayerIndex = playerIndex
                return
            }
        } else {
            finalizePlay(playedCard, playerIndex: playerIndex)
        }
    }

    private var pendingWildPlayerIndex: Int?

    func chooseWildColor(_ color: CardColor) {
        guard case .choosingColor(var card) = phase, let idx = pendingWildPlayerIndex else { return }
        card.chosenColor = color
        pendingWildPlayerIndex = nil
        phase = .playing
        finalizePlay(card, playerIndex: idx)
    }

    private func finalizePlay(_ card: Card, playerIndex: Int) {
        deck.discard(card)

        if players[playerIndex].hand.count == 1 {
            if players[playerIndex].isAI {
                players[playerIndex].hasCalledUno = AIStrategy.shouldCallUnoImmediately()
                if !players[playerIndex].hasCalledUno {
                    pendingUnoCatch = PendingUnoCatch(playerID: players[playerIndex].id, deadline: Date().addingTimeInterval(unoCatchWindow))
                }
            } else {
                pendingUnoCatch = PendingUnoCatch(playerID: players[playerIndex].id, deadline: Date().addingTimeInterval(unoCatchWindow))
            }
        }

        if players[playerIndex].hand.isEmpty {
            endRound(winnerIndex: playerIndex)
            return
        }

        applyEffectAndAdvance(of: card, from: playerIndex)
    }

    private func applyEffectAndAdvance(of card: Card, from playerIndex: Int) {
        switch card.value {
        case .skip:
            advanceTurn(steps: 2, from: playerIndex)
        case .reverse:
            direction.toggle()
            advanceTurn(steps: players.count == 2 ? 2 : 1, from: playerIndex)
        case .drawTwo:
            advanceTurn(steps: 1, from: playerIndex)
            forceDraw(count: 2, onPlayerIndex: currentPlayerIndex)
            advanceTurn(steps: 1, from: currentPlayerIndex)
        case .wildDrawFour:
            advanceTurn(steps: 1, from: playerIndex)
            forceDraw(count: 4, onPlayerIndex: currentPlayerIndex)
            advanceTurn(steps: 1, from: currentPlayerIndex)
        default:
            advanceTurn(steps: 1, from: playerIndex)
        }
        advanceIfAITurn()
    }

    private func forceDraw(count: Int, onPlayerIndex: Int) {
        for _ in 0..<count {
            if let c = deck.draw() { players[onPlayerIndex].hand.append(c) }
        }
    }

    private func advanceTurn(steps: Int, from index: Int) {
        var newIndex = index
        for _ in 0..<steps {
            newIndex = nextIndex(from: newIndex)
        }
        currentPlayerIndex = newIndex
    }

    private func nextIndex(from index: Int) -> Int {
        let count = players.count
        return (index + direction.rawValue + count) % count
    }

    // MARK: - Drawing

    func humanDraw() {
        guard let player = currentPlayer, !player.isAI, phase == .playing else { return }
        drawForCurrentPlayer()
    }

    private func drawForCurrentPlayer() {
        guard let card = deck.draw() else { return }
        players[currentPlayerIndex].hand.append(card)
        hapticPlay()
        if let top = topCard, card.canPlay(on: top), players[currentPlayerIndex].isAI {
            attemptPlay(card, playerIndex: currentPlayerIndex)
        } else {
            advanceTurn(steps: 1, from: currentPlayerIndex)
            advanceIfAITurn()
        }
    }

    // MARK: - UNO call

    func callUno(playerID: UUID) {
        guard let idx = players.firstIndex(where: { $0.id == playerID }) else { return }
        guard players[idx].hand.count <= 1 else { return }
        players[idx].hasCalledUno = true
        if pendingUnoCatch?.playerID == playerID { pendingUnoCatch = nil }
        hapticSuccess()
    }

    func catchFailureToCallUno() {
        guard let pending = pendingUnoCatch, let idx = players.firstIndex(where: { $0.id == pending.playerID }) else { return }
        forceDraw(count: 2, onPlayerIndex: idx)
        pendingUnoCatch = nil
        hapticError()
        showToast(L.t("game.unoPenalty"))
    }

    func checkUnoTimeout() {
        guard let pending = pendingUnoCatch, Date() >= pending.deadline else { return }
        catchFailureToCallUno()
    }

    // MARK: - AI turn loop

    private func advanceIfAITurn() {
        guard phase == .playing, let player = currentPlayer, player.isAI else { return }
        isAIThinking = true
        let delay = Double.random(in: 0.8...1.6)
        let index = currentPlayerIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.currentPlayerIndex == index, self.phase == .playing else { return }
            self.isAIThinking = false
            self.performAITurn(index: index)
        }
    }

    private func performAITurn(index: Int) {
        guard let top = topCard else { return }
        let hand = players[index].hand
        let opponentMin = players.enumerated()
            .filter { $0.offset != index }
            .map { $0.element.hand.count }
            .min() ?? 99

        if let chosen = AIStrategy.chooseCard(hand: hand, topCard: top, opponentLowestCardCount: opponentMin) {
            attemptPlay(chosen, playerIndex: index)
        } else {
            drawForCurrentPlayer()
        }
    }

    // MARK: - Round / game end

    private func endRound(winnerIndex: Int) {
        roundWinnerID = players[winnerIndex].id
        var points = 0
        for (i, p) in players.enumerated() where i != winnerIndex {
            points += p.hand.reduce(0) { $0 + $1.value.scoreValue }
        }
        lastRoundPoints = points
        players[winnerIndex].totalScore += points
        phase = .roundEnd
        hapticSuccess()

        if players[winnerIndex].totalScore >= Self.targetScore {
            gameWinnerID = players[winnerIndex].id
        }
    }

    func continueAfterRound() {
        if gameWinnerID != nil {
            phase = .gameEnd
        } else {
            startNewRound()
        }
    }

    func returnToMenu() {
        phase = .menu
        players = []
        gameWinnerID = nil
    }

    // MARK: - Feedback helpers

    private func showToast(_ text: String) {
        toastWorkItem?.cancel()
        toastMessage = text
        let work = DispatchWorkItem { [weak self] in self?.toastMessage = nil }
        toastWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
    }

    private func hapticPlay() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func hapticError() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    private func hapticSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
