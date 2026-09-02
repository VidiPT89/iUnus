import Foundation

// MARK: - Online matches (GameKit)

extension GameViewModel {
    /// Starts a fresh online match dealt from scratch. Called only on the device GameKit
    /// designated as the first turn — every other participant instead calls `loadOnlineState`
    /// once the turn (and its dealt state) reaches them.
    func startOnlineMatch(players: [Player], localPlayerID: UUID, participantMapping: [String: UUID], delegate: OnlineMatchDelegate) {
        mode = .online
        onlineLocalPlayerID = localPlayerID
        onlineParticipantMapping = participantMapping
        onlineDelegate = delegate
        self.players = players
        gameWinnerID = nil
        startNewRound()
    }

    /// Loads state decoded from an in-progress `GKTurnBasedMatch`'s data, resuming the online
    /// game on this device for whichever player's turn it now is.
    func loadOnlineState(_ state: OnlineMatchState, localPlayerID: UUID, participantMapping: [String: UUID], delegate: OnlineMatchDelegate) {
        mode = .online
        onlineLocalPlayerID = localPlayerID
        onlineParticipantMapping = participantMapping
        onlineDelegate = delegate
        players = state.players
        deck = state.deck
        currentPlayerIndex = state.currentPlayerIndex
        direction = state.direction
        pendingDrawStack = state.pendingDrawStack
        // Turn-based matches have no shared clock between devices, so an open catch window is
        // reconstructed without a real deadline — `checkUnoTimeout()`'s local 0.3s poll compares
        // against `.distantFuture` and never auto-penalizes here; only a tap on `catchUno` (or the
        // offender calling UNO themselves) resolves it, same as it already does for a human catch.
        pendingUnoCatch = state.pendingUnoCatchPlayerID.map { PendingUnoCatch(playerID: $0, deadline: .distantFuture) }
        roundWinnerID = state.roundWinnerID
        gameWinnerID = state.gameWinnerID
        justDrawnCard = nil
        phase = state.phase == .gameEnd ? .gameEnd : .playing
    }

    func exportOnlineState() -> OnlineMatchState {
        OnlineMatchState(
            players: players,
            deck: deck,
            currentPlayerIndex: currentPlayerIndex,
            direction: direction,
            pendingDrawStack: pendingDrawStack,
            phase: gameWinnerID != nil ? .gameEnd : .playing,
            roundWinnerID: roundWinnerID,
            gameWinnerID: gameWinnerID,
            pendingUnoCatchPlayerID: pendingUnoCatch?.playerID,
            participantPlayerIDs: onlineParticipantMapping
        )
    }
}
