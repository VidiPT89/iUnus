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

    func attach(gameViewModel: GameViewModel) {
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
        guard let data = match.matchData, !data.isEmpty, let state = try? JSONDecoder().decode(OnlineMatchState.self, from: data) else {
            startFreshMatch(match: match)
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
        guard players.count >= 2, let localPlayerID = mapping[GKLocalPlayer.local.gamePlayerID] else { return }

        gameViewModel.startOnlineMatch(players: players, localPlayerID: localPlayerID, participantMapping: mapping, delegate: self)
    }

    private func nextParticipant(in match: GKTurnBasedMatch, for playerID: UUID, mapping: [String: UUID]) -> GKTurnBasedParticipant? {
        match.participants.first { participant in
            guard let gamePlayerID = participant.player?.gamePlayerID else { return false }
            return mapping[gamePlayerID] == playerID
        }
    }

    private func handleTurnCompletion(_ error: Error?) {
        guard let error else { return }
        statusMessage = error.localizedDescription
    }
}

// MARK: - OnlineMatchDelegate

extension OnlineMatchCoordinator: OnlineMatchDelegate {
    func gameViewModelDidUpdateOnlineState(_ viewModel: GameViewModel) {
        guard let match = activeMatch else { return }
        let state = viewModel.exportOnlineState()
        guard let data = try? JSONEncoder().encode(state) else { return }
        guard let next = nextParticipant(in: match, for: state.players[state.currentPlayerIndex].id, mapping: state.participantPlayerIDs) else { return }
        match.endTurn(withNextParticipants: [next], turnTimeout: GKTurnTimeoutDefault, match: data) { [weak self] error in
            Task { @MainActor in self?.handleTurnCompletion(error) }
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
        match.endMatchInTurn(withMatch: data) { [weak self] error in
            Task { @MainActor in
                self?.handleTurnCompletion(error)
                self?.activeMatch = nil
            }
        }
    }

    func gameViewModelDidRequestQuit(_ viewModel: GameViewModel) {
        guard let match = activeMatch else { return }
        let isLocalTurn = match.currentParticipant?.player?.gamePlayerID == GKLocalPlayer.local.gamePlayerID
        if isLocalTurn {
            let remaining = match.participants.filter { $0.player?.gamePlayerID != GKLocalPlayer.local.gamePlayerID }
            match.participantQuitInTurn(with: .quit, nextParticipants: remaining, turnTimeout: GKTurnTimeoutDefault, match: match.matchData ?? Data()) { [weak self] error in
                Task { @MainActor in self?.handleTurnCompletion(error) }
            }
        } else {
            match.participantQuitOutOfTurn(with: .quit) { [weak self] error in
                Task { @MainActor in self?.handleTurnCompletion(error) }
            }
        }
        activeMatch = nil
    }
}

// MARK: - GKLocalPlayerListener

extension OnlineMatchCoordinator: GKLocalPlayerListener {
    nonisolated func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
        Task { @MainActor in
            self.activeMatch = match
            self.loadCurrentTurn(match: match)
        }
    }

    nonisolated func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        Task { @MainActor in
            self.activeMatch = match
            self.loadCurrentTurn(match: match)
        }
    }
}
