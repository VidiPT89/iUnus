import Foundation

// MARK: - UNO call

extension GameViewModel {
    /// Closes an open UNO-catch window with no penalty the instant the seat it was waiting on
    /// takes its turn — called at the top of both `attemptPlay` and `drawForCurrentPlayer` so
    /// whichever action that seat takes first counts as "the next turn beginning". A `catchUno`
    /// tap on the offender that beats this to the punch still applies the 2-card penalty as usual.
    func closeUnoCatchWindowIfBlocking(_ playerIndex: Int) {
        guard let pending = pendingUnoCatch, pending.blockingPlayerIndex == playerIndex else { return }
        pendingUnoCatch = nil
    }

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
}
