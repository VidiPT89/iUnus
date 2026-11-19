import Foundation

// MARK: - AI turn loop

extension GameViewModel {
    func advanceIfAITurn() {
        guard mode == .local, !isSuspended, pendingWildDraw4Challenge == nil, phase == .playing, let player = currentPlayer, player.isAI else { return }
        turnWorkItem?.cancel()
        isAIThinking = true
        let delay = Double.random(in: aiSpeed.delayRange)
        let index = currentPlayerIndex
        let playerID = player.id
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.currentPlayerIndex == index, self.currentPlayer?.id == playerID, self.phase == .playing else { return }
            self.isAIThinking = false
            if let pending = self.pendingUnoCatch, pending.playerID != playerID {
                self.catchFailureToCallUno()
            }
            self.performAITurn(index: index)
        }
        turnWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
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
            .filter { $0.offset != index && !$0.element.hand.isEmpty }
            .map { $0.element.hand.count }
            .min() ?? 99

        if let chosen = AIStrategy.chooseCard(hand: hand, topCard: top, opponentLowestCardCount: opponentMin, difficulty: aiDifficulty, enforceWildDrawFourRestriction: enforceWildDrawFourRestriction) {
            attemptPlay(chosen, playerIndex: index)
        } else {
            drawForCurrentPlayer()
        }
    }
}
