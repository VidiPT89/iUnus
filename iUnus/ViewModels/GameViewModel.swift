import Foundation
import Combine
import UIKit
import AudioToolbox

/// Core game state and the local play/draw flow. Online-match wiring lives in
/// `GameViewModel+Online.swift`, the AI turn loop in `GameViewModel+AI.swift`, round/game
/// conclusion in `GameViewModel+RoundEnd.swift`, and haptics/sound/toast feedback in
/// `GameViewModel+Feedback.swift`. Members those extensions touch are `internal` rather than
/// `private` — Swift has no cross-file "type-private" level, so this is the usual cost of
/// splitting one type's implementation across files while keeping it out of other modules.
@MainActor
final class GameViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var deck = Deck()
    @Published var currentPlayerIndex: Int = 0
    @Published var direction: TurnDirection = .clockwise
    @Published var phase: GamePhase = .menu
    @Published var pendingUnoCatch: PendingUnoCatch?
    @Published var toastMessage: String?
    @Published var roundWinnerID: UUID?
    @Published var gameWinnerID: UUID?
    @Published var lastRoundPoints: Int = 0
    @Published var isAIThinking: Bool = false
    @Published var justDrawnCard: Card?
    @Published var pendingDrawStack: Int = 0
    @Published private(set) var hasSavedGame: Bool = GameSaveStore.hasSave
    @Published var mode: GameMode = .local
    @Published private(set) var roundFinishOrder: [UUID] = []

    static let targetScore = 500
    private let unoCatchWindow: TimeInterval = 3.0
    var toastWorkItem: DispatchWorkItem?

    var onlineLocalPlayerID: UUID?
    var onlineParticipantMapping: [String: UUID] = [:]
    weak var onlineDelegate: OnlineMatchDelegate?

    var topCard: Card? { deck.topCard }
    var currentPlayer: Player? { players.indices.contains(currentPlayerIndex) ? players[currentPlayerIndex] : nil }
    var humanPlayer: Player? { players.first(where: { !$0.isAI }) }

    /// In local games this is simply the one human seat; in an online match it's whichever
    /// seat belongs to this device, since every participant is a real, non-AI player there.
    var localViewPlayer: Player? {
        mode == .online ? players.first(where: { $0.id == onlineLocalPlayerID }) : humanPlayer
    }

    var opponentPlayers: [Player] {
        mode == .online ? players.filter { $0.id != onlineLocalPlayerID } : players.filter { $0.isAI }
    }

    var isLocalTurn: Bool {
        mode == .online ? currentPlayer?.id == onlineLocalPlayerID : currentPlayer?.isAI == false
    }

    private weak var settings: SettingsViewModel?
    var aiDifficulty: AIDifficulty { settings?.aiDifficulty ?? .normal }
    var aiSpeed: AISpeed { settings?.aiSpeed ?? .normal }
    private var houseRulesActive: Bool { settings?.ruleSet == .houseRules }
    /// Official rules only: a Wild Draw Four may not be played while the player holds a card
    /// matching the active color. House rules (and online, which enforces official elsewhere) waive it.
    var enforceWildDrawFourRestriction: Bool { !houseRulesActive }

    /// Under House Rules a round continues, skipping finished players, until only one player
    /// still holds cards; Official Rules (and online, which is always Official) end the round
    /// the instant the first player empties their hand — unchanged from before this feature.
    private var playUntilOnePlayerRemains: Bool { houseRulesActive && mode != .online }

    private func activePlayerIndices() -> [Int] {
        players.indices.filter { !roundFinishOrder.contains(players[$0].id) }
    }

    func configure(settings: SettingsViewModel) {
        self.settings = settings
    }

    func startNewGame(opponentCount: Int) {
        clearSavedGame()
        let clamped = max(1, min(3, opponentCount))
        var newPlayers = [Player(name: L.t("player.you"), kind: .human)]
        for i in 1...clamped {
            newPlayers.append(Player(name: String(format: L.t("player.opponent"), i), kind: .ai))
        }
        players = newPlayers
        gameWinnerID = nil
        startNewRound()
    }

    func resumeSavedGame() {
        guard let saved = GameSaveStore.load() else {
            hasSavedGame = false
            return
        }
        players = saved.players
        deck = saved.deck
        currentPlayerIndex = saved.currentPlayerIndex
        direction = saved.direction
        pendingDrawStack = saved.pendingDrawStack
        pendingUnoCatch = nil
        roundWinnerID = nil
        roundFinishOrder = saved.roundFinishOrder
        gameWinnerID = nil
        justDrawnCard = nil
        phase = .playing
        advanceIfAITurn()
    }

    func quitToMenu() {
        if mode == .online {
            onlineDelegate?.gameViewModelDidRequestQuit(self)
        } else {
            saveProgressIfActive()
        }
        returnToMenu()
    }

    func saveProgressIfActive() {
        guard phase == .playing, !players.isEmpty else { return }
        let save = SavedGame(
            players: players,
            deck: deck,
            currentPlayerIndex: currentPlayerIndex,
            direction: direction,
            pendingDrawStack: pendingDrawStack,
            roundFinishOrder: roundFinishOrder
        )
        GameSaveStore.save(save)
        hasSavedGame = true
    }

    func clearSavedGame() {
        GameSaveStore.clear()
        hasSavedGame = false
    }

    /// Routes post-mutation bookkeeping by mode: local games persist to disk and, if it's now
    /// an AI seat's turn, advance it; online games instead hand the new state to GameKit via
    /// the delegate. Consolidating this in one place keeps local-mode behavior byte-for-byte
    /// identical to before online support was added.
    func afterTurnMutation() {
        switch mode {
        case .local:
            saveProgressIfActive()
            advanceIfAITurn()
        case .online:
            onlineDelegate?.gameViewModelDidUpdateOnlineState(self)
        }
    }

    func syncProgress() {
        switch mode {
        case .local:
            saveProgressIfActive()
        case .online:
            onlineDelegate?.gameViewModelDidUpdateOnlineState(self)
        }
    }

    func startNewRound() {
        deck = Deck()
        direction = .clockwise
        pendingUnoCatch = nil
        pendingDrawStack = 0
        roundWinnerID = nil
        roundFinishOrder = []
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
            self.afterTurnMutation()
        }
    }

    // MARK: - Playing cards

    func humanPlay(_ card: Card) {
        guard isLocalTurn, phase == .playing, currentPlayer != nil else { return }
        attemptPlay(card, playerIndex: currentPlayerIndex)
    }

    func attemptPlay(_ card: Card, playerIndex: Int) {
        guard players.indices.contains(playerIndex) else { return }
        guard let top = topCard else { return }
        guard let handIndex = players[playerIndex].hand.firstIndex(where: { $0.id == card.id }) else { return }

        // Facing an active house-rule stack, only another +2/+4 may answer — its color
        // doesn't need to match, it just needs to be a Draw Two or Wild Draw Four.
        let isLegal = pendingDrawStack > 0
            ? card.value.drawPenaltyAmount != nil
            : card.canPlay(on: top, hand: players[playerIndex].hand, enforceWildDrawFourRestriction: enforceWildDrawFourRestriction)
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
            handlePlayerFinished(playerIndex: playerIndex, playedCard: card)
            return
        }

        applyEffectAndAdvance(of: card, from: playerIndex)
    }

    /// Official/online: the round ends the instant a hand empties. House Rules: the finisher
    /// takes their placement and leaves the rotation, but the round keeps going — still applying
    /// the card's effect (Skip/Reverse/+2/+4) among the remaining active players — until only
    /// one player still holds cards.
    private func handlePlayerFinished(playerIndex: Int, playedCard: Card) {
        guard players.indices.contains(playerIndex) else { return }
        guard playUntilOnePlayerRemains else {
            endRound(winnerIndex: playerIndex)
            return
        }
        let finishedID = players[playerIndex].id
        if !roundFinishOrder.contains(finishedID) {
            roundFinishOrder.append(finishedID)
        }
        if activePlayerIndices().count <= 1 {
            finishHouseRulesRound()
            return
        }
        applyEffectAndAdvance(of: playedCard, from: playerIndex)
    }

    /// Concludes a House Rules round once only one player still holds cards: the round winner
    /// is whoever finished first, scored the same as always against everyone else's final hands
    /// (which is equivalent to just the last remaining player's hand, since everyone else is empty).
    private func finishHouseRulesRound() {
        guard let winnerID = roundFinishOrder.first, let winnerIndex = players.firstIndex(where: { $0.id == winnerID }) else { return }
        endRound(winnerIndex: winnerIndex)
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
        afterTurnMutation()
    }

    func forceDraw(count: Int, onPlayerIndex: Int) {
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

    /// Steps to the next seat in turn order; under the House Rules "last player standing"
    /// variant this skips seats already recorded in `roundFinishOrder`. The `attempts` guard
    /// bounds the loop to one lap so a corrupt/edge state can never spin forever.
    private func nextIndex(from index: Int) -> Int {
        let count = players.count
        guard count > 0 else { return 0 }
        var newIndex = index
        var attempts = 0
        repeat {
            newIndex = (newIndex + direction.rawValue + count) % count
            attempts += 1
        } while playUntilOnePlayerRemains && roundFinishOrder.contains(players[newIndex].id) && attempts <= count
        return newIndex
    }

    // MARK: - Drawing

    func humanDraw() {
        guard isLocalTurn, phase == .playing, currentPlayer != nil else { return }
        drawForCurrentPlayer()
    }

    func drawForCurrentPlayer() {
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
            afterTurnMutation()
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
        if let top = topCard,
           card.canPlay(on: top, hand: players[currentPlayerIndex].hand, enforceWildDrawFourRestriction: enforceWildDrawFourRestriction),
           players[currentPlayerIndex].isAI {
            attemptPlay(card, playerIndex: currentPlayerIndex)
        } else {
            advanceTurn(steps: 1, from: currentPlayerIndex)
            afterTurnMutation()
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
        afterTurnMutation()
    }

    // MARK: - UNO call

    func callUno(playerID: UUID) {
        guard let idx = players.firstIndex(where: { $0.id == playerID }) else { return }
        guard players[idx].hand.count <= 1 else { return }
        players[idx].hasCalledUno = true
        if pendingUnoCatch?.playerID == playerID { pendingUnoCatch = nil }
        hapticSuccess()
        syncProgress()
    }

    func catchFailureToCallUno() {
        guard let pending = pendingUnoCatch, let idx = players.firstIndex(where: { $0.id == pending.playerID }) else { return }
        forceDraw(count: 2, onPlayerIndex: idx)
        pendingUnoCatch = nil
        hapticError()
        showToast(L.t("game.unoPenalty"))
        syncProgress()
    }

    func checkUnoTimeout() {
        guard let pending = pendingUnoCatch, Date() >= pending.deadline else { return }
        catchFailureToCallUno()
    }
}
