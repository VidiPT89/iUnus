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
        // The window (if open) always blocks on whoever's turn this snapshot was exported for —
        // that's exactly the seat GameKit just handed the turn to — so it closes the instant this
        // device's local player (or an AI seat, in a mixed local/online build) takes their turn,
        // same rule as local play.
        pendingUnoCatch = state.pendingUnoCatchPlayerID.map { PendingUnoCatch(playerID: $0, blockingPlayerIndex: state.currentPlayerIndex) }
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
