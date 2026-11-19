import Foundation
import GameKit

/// Owns the active `GKTurnBasedMatch` and is the sole place that talks to GameKit's turn-based
/// API. Attaches to the app's single shared `GameViewModel` instance so an online match reuses
/// the exact same dealing/play/draw logic and UI as local games; `GameViewModel` only knows it
/// has an `OnlineMatchDelegate` to notify, not that GameKit exists.
@MainActor
final class OnlineMatchCoordinator: NSObject, ObservableObject {
    @Published var isPresentingMatchmaker = false
    @Published var statusMessage: String?

    private weak var gameViewModel: GameViewModel?
    private var activeMatch: GKTurnBasedMatch?
    private var didRegisterListener = false
    private var pendingRetry: (() -> Void)?

    var canRetryUpdate: Bool { pendingRetry != nil }
    private var gameViewModelIsWriting: Bool { gameViewModel?.isOnlineUpdatePending == true }

    func attach(gameViewModel: GameViewModel) {
        guard self.gameViewModel !== gameViewModel else { return }
        self.gameViewModel = gameViewModel
        registerListenerIfNeeded()
        NotificationCenter.default.addObserver(self, selector: #selector(handleAuthenticated), name: .gameCenterDidAuthenticate, object: nil)
    }

    @objc private func handleAuthenticated() {
        registerListenerIfNeeded()
        resumeMostRelevantMatch()
    }

    private func registerListenerIfNeeded() {
        guard !didRegisterListener else { return }
        didRegisterListener = true
        GKLocalPlayer.local.register(self)
    }

    /// Looks for an in-progress match where it's already the local player's turn, so the app
    /// can resume straight into it after launch or after a turn-notification tap — the same
    /// role `GKTurnBasedMatch.loadMatches` plays when no push has been received yet.
    func resumeMostRelevantMatch() {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        GKTurnBasedMatch.loadMatches { [weak self] matches, error in
            guard let self else { return }
            Task { @MainActor in
                guard self.gameViewModel?.phase == .menu else { return }
                if let error { self.statusMessage = error.localizedDescription; return }
                guard let match = matches?.first(where: {
                    $0.status == .open && $0.currentParticipant?.player?.gamePlayerID == GKLocalPlayer.local.gamePlayerID
                }) else { return }
                self.activeMatch = match
                self.loadCurrentTurn(match: match)
            }
        }
    }

    private func loadCurrentTurn(match: GKTurnBasedMatch) {
        guard let gameViewModel else { return }
        isPresentingMatchmaker = false
        guard let data = match.matchData, !data.isEmpty else {
            startFreshMatch(match: match)
            return
        }
        guard let state = try? JSONDecoder().decode(OnlineMatchState.self, from: data), state.isValid else {
            statusMessage = L.t("online.invalidState")
            return
        }
        guard let localPlayerID = state.participantPlayerIDs[GKLocalPlayer.local.gamePlayerID] else { return }
        gameViewModel.loadOnlineState(state, localPlayerID: localPlayerID, participantMapping: state.participantPlayerIDs, delegate: self)
    }

    /// Only the participant GameKit hands the very first turn to (the match's creator) deals
    /// the game — every other device only ever receives already-dealt state via `matchData`.
    private func startFreshMatch(match: GKTurnBasedMatch) {
        guard let gameViewModel else { return }
        guard match.currentParticipant?.player?.gamePlayerID == GKLocalPlayer.local.gamePlayerID else { return }

        var players: [Player] = []
        var mapping: [String: UUID] = [:]
        for participant in match.participants {
            guard let player = participant.player else { continue }
            let dealt = Player(name: player.displayName, kind: .human)
            mapping[player.gamePlayerID] = dealt.id
            players.append(dealt)
        }
        guard players.count == match.participants.count, players.count >= 2, let localPlayerID = mapping[GKLocalPlayer.local.gamePlayerID] else { statusMessage = L.t("online.waitingPlayers"); return }

        gameViewModel.startOnlineMatch(players: players, localPlayerID: localPlayerID, participantMapping: mapping, delegate: self)
    }

    private func nextParticipant(in match: GKTurnBasedMatch, for playerID: UUID, mapping: [String: UUID]) -> GKTurnBasedParticipant? {
        match.participants.first { participant in
            guard let gamePlayerID = participant.player?.gamePlayerID else { return false }
            return mapping[gamePlayerID] == playerID
        }
    }

    func retryPendingUpdate() {
        statusMessage = nil
        pendingRetry?()
    }

    /// Keep actions locked until GameKit acknowledges the snapshot. A failed write retains
    /// exactly the same operation for retry instead of letting the local game diverge further.
    private func submit(match: GKTurnBasedMatch, operation: @escaping (@escaping @Sendable (Error?) -> Void) -> Void) {
        guard activeMatch?.matchID == match.matchID else { return }
        gameViewModel?.isOnlineUpdatePending = true
        pendingRetry = { [weak self] in self?.submit(match: match, operation: operation) }
        operation { [weak self] error in
            Task { @MainActor in
                guard let self, self.activeMatch?.matchID == match.matchID else { return }
                if let error {
                    self.statusMessage = error.localizedDescription
                } else {
                    self.pendingRetry = nil
                    self.statusMessage = nil
                    self.gameViewModel?.isOnlineUpdatePending = false
                }
            }
        }
    }

}

// MARK: - OnlineMatchDelegate

extension OnlineMatchCoordinator: OnlineMatchDelegate {
    func gameViewModelDidUpdateOnlineState(_ viewModel: GameViewModel) {
        guard let match = activeMatch else { return }
        let state = viewModel.exportOnlineState()
        guard let data = try? JSONEncoder().encode(state) else { return }
        guard state.isValid,
              let next = nextParticipant(in: match, for: state.players[state.currentPlayerIndex].id, mapping: state.participantPlayerIDs) else {
            statusMessage = L.t("online.invalidState")
            return
        }
        // A Skip/Reverse may leave the same seat playing again. UNO/catch updates also
        // preserve that turn: only hand over when the engine selected another participant.
        if state.players[state.currentPlayerIndex].id == viewModel.onlineLocalPlayerID {
            submit(match: match) { done in match.saveCurrentTurn(withMatch: data, completionHandler: done) }
        } else {
            submit(match: match) { done in
                match.endTurn(withNextParticipants: [next], turnTimeout: GKTurnTimeoutDefault, match: data, completionHandler: done)
            }
        }
    }

    func gameViewModelDidEndGame(_ viewModel: GameViewModel, winnerIndex: Int) {
        guard let match = activeMatch else { return }
        var state = viewModel.exportOnlineState()
        state.phase = .gameEnd
        guard let data = try? JSONEncoder().encode(state) else { return }
        let winnerID = state.players[winnerIndex].id
        for participant in match.participants {
            guard let gamePlayerID = participant.player?.gamePlayerID, let playerID = state.participantPlayerIDs[gamePlayerID] else { continue }
            participant.matchOutcome = playerID == winnerID ? .won : .lost
        }
        submit(match: match) { done in match.endMatchInTurn(withMatch: data, completionHandler: done) }
    }

    func gameViewModelDidRequestQuit(_ viewModel: GameViewModel) {
        // Closing the table is not a resignation. Game Center keeps the match available
        // in its match list; a pending network write must be resolved before closing.
        guard !viewModel.isOnlineUpdatePending else { return }
        activeMatch = nil
        pendingRetry = nil
    }

}

// MARK: - GKLocalPlayerListener

extension OnlineMatchCoordinator: GKLocalPlayerListener {
    nonisolated func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
        Task { @MainActor in
            guard !self.gameViewModelIsWriting else { return }
            guard didBecomeActive || self.activeMatch?.matchID == match.matchID || self.gameViewModel?.phase == .menu else { return }
            self.gameViewModel?.saveProgressIfActive()
            self.activeMatch = match
            self.loadCurrentTurn(match: match)
        }
    }

    nonisolated func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        Task { @MainActor in
            guard !self.gameViewModelIsWriting, self.activeMatch?.matchID == match.matchID else { return }
            self.activeMatch = match
            self.loadCurrentTurn(match: match)
        }
    }
}
