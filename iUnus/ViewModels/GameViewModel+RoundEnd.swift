import Foundation

// MARK: - Round / game end

extension GameViewModel {
    func endRound(winnerIndex: Int) {
        guard players.indices.contains(winnerIndex) else { return }
        roundWinnerID = players[winnerIndex].id

        // Online matches use official rules only and are decided by the first round, rather
        // than local mode's running score race to `targetScore` across multiple rounds.
        if mode == .online {
            gameWinnerID = players[winnerIndex].id
            phase = .gameEnd
            hapticSuccess()
            onlineDelegate?.gameViewModelDidEndGame(self, winnerIndex: winnerIndex)
            return
        }

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
            clearSavedGame()
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
        mode = .local
        onlineLocalPlayerID = nil
        onlineParticipantMapping = [:]
        onlineDelegate = nil
    }
}
