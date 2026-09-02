import Foundation
import Combine
import UIKit
import AudioToolbox

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var players: [Player] = []
    @Published private(set) var deck = Deck()
    @Published private(set) var currentPlayerIndex: Int = 0
    @Published private(set) var direction: TurnDirection = .clockwise
    @Published var phase: GamePhase = .menu
    @Published private(set) var pendingUnoCatch: PendingUnoCatch?
    @Published var toastMessage: String?
    @Published private(set) var roundWinnerID: UUID?
    @Published private(set) var gameWinnerID: UUID?
    @Published private(set) var lastRoundPoints: Int = 0
    @Published private(set) var isAIThinking: Bool = false
    @Published private(set) var justDrawnCard: Card?
    @Published private(set) var pendingDrawStack: Int = 0

    static let targetScore = 500
    private let unoCatchWindow: TimeInterval = 3.0
    private var toastWorkItem: DispatchWorkItem?

    var topCard: Card? { deck.topCard }
    var currentPlayer: Player? { players.indices.contains(currentPlayerIndex) ? players[currentPlayerIndex] : nil }
    var humanPlayer: Player? { players.first(where: { !$0.isAI }) }

    private weak var settings: SettingsViewModel?
    private var aiDifficulty: AIDifficulty { settings?.aiDifficulty ?? .normal }
    private var houseRulesActive: Bool { settings?.ruleSet == .houseRules }

    func configure(settings: SettingsViewModel) {
        self.settings = settings
    }

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
        pendingUnoCatch = nil
        pendingDrawStack = 0
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
        for i in players.indices { players[i].hand.sortForDisplay() }
        currentPlayerIndex = 0

        if let starter {
            switch starter.value {
            case .skip:
                currentPlayerIndex = nextIndex(from: 0)
            case .reverse:
                direction.toggle()
                // House rule: same as a Reverse played mid-round — with only 2 players
                // this acts as a Skip, and with 3+ the dealer (player 0) is skipped so
                // the next player in the new (counter-clockwise) direction goes first.
                currentPlayerIndex = nextIndex(from: 0)
            case .drawTwo:
                forceDraw(count: 2, onPlayerIndex: 0)
                currentPlayerIndex = nextIndex(from: 0)
            default:
                break
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { [weak self] in
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
        guard players.indices.contains(playerIndex) else { return }
        guard let top = topCard else { return }
        guard let handIndex = players[playerIndex].hand.firstIndex(where: { $0.id == card.id }) else { return }

        // Facing an active house-rule stack, only another +2/+4 may answer — its color
        // doesn't need to match, it just needs to be a Draw Two or Wild Draw Four.
        let isLegal = pendingDrawStack > 0 ? card.value.drawPenaltyAmount != nil : card.canPlay(on: top)
        guard isLegal else {
            if !players[playerIndex].isAI { hapticError(); showToast(L.t("game.invalidMove")) }
            return
        }

        var playedCard = players[playerIndex].hand.remove(at: handIndex)
        hapticPlay()
        playCardSound()

        if playedCard.value.isWild {
            if players[playerIndex].isAI {
                let color = AIStrategy.chooseColor(hand: players[playerIndex].hand, excluding: playedCard, difficulty: aiDifficulty)
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
        guard players.indices.contains(playerIndex) else { return }
        deck.discard(card)

        if players[playerIndex].hand.count == 1 {
            if players[playerIndex].isAI {
                players[playerIndex].hasCalledUno = AIStrategy.shouldCallUnoImmediately(difficulty: aiDifficulty)
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
        guard players.indices.contains(playerIndex) else { return }
        switch card.value {
        case .skip:
            advanceTurn(steps: 2, from: playerIndex)
        case .reverse:
            direction.toggle()
            advanceTurn(steps: players.count == 2 ? 2 : 1, from: playerIndex)
        case .drawTwo, .wildDrawFour:
            let amount = card.value.drawPenaltyAmount ?? 0
            if houseRulesActive {
                // Accumulate onto any pending stack rather than resolving it immediately,
                // so the next player gets the chance to answer with another +2/+4.
                pendingDrawStack += amount
                advanceTurn(steps: 1, from: playerIndex)
                showToast(String(format: L.t("game.stackPending"), pendingDrawStack))
            } else {
                advanceTurn(steps: 1, from: playerIndex)
                forceDraw(count: amount, onPlayerIndex: currentPlayerIndex)
                advanceTurn(steps: 1, from: currentPlayerIndex)
            }
        default:
            advanceTurn(steps: 1, from: playerIndex)
        }
        advanceIfAITurn()
    }

    private func forceDraw(count: Int, onPlayerIndex: Int) {
        guard players.indices.contains(onPlayerIndex) else { return }
        for _ in 0..<count {
            guard deck.canDraw, let c = deck.draw() else {
                showToast(L.t("game.deckExhausted"))
                break
            }
            players[onPlayerIndex].hand.append(c)
        }
        players[onPlayerIndex].hand.sortForDisplay()
    }

    private func advanceTurn(steps: Int, from index: Int) {
        guard !players.isEmpty else { return }
        var newIndex = index
        for _ in 0..<steps {
            newIndex = nextIndex(from: newIndex)
        }
        currentPlayerIndex = newIndex
    }

    private func nextIndex(from index: Int) -> Int {
        let count = players.count
        guard count > 0 else { return 0 }
        return (index + direction.rawValue + count) % count
    }

    // MARK: - Drawing

    func humanDraw() {
        guard let player = currentPlayer, !player.isAI, phase == .playing else { return }
        drawForCurrentPlayer()
    }

    private func drawForCurrentPlayer() {
        guard players.indices.contains(currentPlayerIndex) else { return }
        if pendingDrawStack > 0 {
            drawPendingStack()
            return
        }
        // House rules: keep drawing until a legally-playable card turns up (a Wild always
        // counts). Official rules always draw exactly one card, unchanged.
        let keepDrawingUntilPlayable = houseRulesActive
        var lastDrawn: Card?
        repeat {
            guard deck.canDraw, let card = deck.draw() else { break }
            players[currentPlayerIndex].hand.append(card)
            lastDrawn = card
        } while keepDrawingUntilPlayable && !(topCard.map { lastDrawn!.canPlay(on: $0) } ?? false)

        guard let card = lastDrawn else {
            showToast(L.t("game.deckExhausted"))
            advanceTurn(steps: 1, from: currentPlayerIndex)
            advanceIfAITurn()
            return
        }
        players[currentPlayerIndex].hand.sortForDisplay()
        hapticPlay()
        playDrawSound()
        justDrawnCard = card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.justDrawnCard?.id == card.id else { return }
            self.justDrawnCard = nil
        }
        if let top = topCard, card.canPlay(on: top), players[currentPlayerIndex].isAI {
            attemptPlay(card, playerIndex: currentPlayerIndex)
        } else {
            advanceTurn(steps: 1, from: currentPlayerIndex)
            advanceIfAITurn()
        }
    }

    /// Resolves an active house-rule stack for the current player: they had no +2/+4 to
    /// answer with, so they take the whole accumulated pile in one safe (reshuffle-aware) draw.
    private func drawPendingStack() {
        guard players.indices.contains(currentPlayerIndex) else { return }
        let amount = pendingDrawStack
        pendingDrawStack = 0
        forceDraw(count: amount, onPlayerIndex: currentPlayerIndex)
        if !players[currentPlayerIndex].isAI { hapticError() }
        showToast(String(format: L.t("game.stackDrawn"), amount))
        advanceTurn(steps: 1, from: currentPlayerIndex)
        advanceIfAITurn()
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
        guard let top = topCard, players.indices.contains(index) else { return }
        let hand = players[index].hand

        if pendingDrawStack > 0 {
            if let stackCard = AIStrategy.chooseStackCard(hand: hand, difficulty: aiDifficulty) {
                attemptPlay(stackCard, playerIndex: index)
            } else {
                drawForCurrentPlayer()
            }
            return
        }

        let opponentMin = players.enumerated()
            .filter { $0.offset != index }
            .map { $0.element.hand.count }
            .min() ?? 99

        if let chosen = AIStrategy.chooseCard(hand: hand, topCard: top, opponentLowestCardCount: opponentMin, difficulty: aiDifficulty) {
            attemptPlay(chosen, playerIndex: index)
        } else {
            drawForCurrentPlayer()
        }
    }

    // MARK: - Round / game end

    private func endRound(winnerIndex: Int) {
        guard players.indices.contains(winnerIndex) else { return }
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
            playWinSound()
            recordMatchStats(winnerIndex: winnerIndex)
        }
    }

    private func recordMatchStats(winnerIndex: Int) {
        guard let human = humanPlayer else { return }
        let humanWon = players[winnerIndex].id == human.id
        MatchStatsStore.shared.recordGameEnd(humanWon: humanWon, humanScore: human.totalScore)
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

    /// Short, non-intrusive feedback using built-in iOS system sound IDs — no bundled
    /// audio assets required, keeping the project free of binary sound files.
    private func playSystemSound(_ id: UInt32) {
        AudioServicesPlaySystemSound(SystemSoundID(id))
    }

    private func playCardSound() { playSystemSound(1104) }
    private func playDrawSound() { playSystemSound(1103) }
    private func playWinSound() { playSystemSound(1025) }
}
