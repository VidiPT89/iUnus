import Foundation

// MARK: - Wild Draw Four challenge (local, Official Rules only)

extension GameViewModel {
    /// The pending challenge, but only when this device's local human is the victim — online
    /// seats and AI victims never reach here (AI resolves itself via `resolveWildDraw4ChallengeIfAIVictim`,
    /// and online play never opens a challenge to begin with; see `attemptPlay`).
    var wildDraw4ChallengeForLocalHuman: PendingWildDraw4Challenge? {
        guard let pending = pendingWildDraw4Challenge, mode == .local,
              players.indices.contains(pending.victimIndex), !players[pending.victimIndex].isAI else { return nil }
        return pending
    }

    /// Auto-resolves an open challenge when the victim is an AI seat, after a thinking delay
    /// matching the normal AI turn pacing. No-ops when the victim is the local human — that case
    /// waits for `resolveWildDraw4Challenge` to be called from the challenge sheet instead.
    func resolveWildDraw4ChallengeIfAIVictim() {
        guard let pending = pendingWildDraw4Challenge,
              players.indices.contains(pending.victimIndex), players[pending.victimIndex].isAI else { return }
        isAIThinking = true
        let delay = Double.random(in: aiSpeed.delayRange)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.pendingWildDraw4Challenge == pending else { return }
            self.isAIThinking = false
            self.resolveWildDraw4Challenge(challenge: AIStrategy.shouldChallengeWildDraw4(difficulty: self.aiDifficulty))
        }
    }

    /// Settles an open Wild Draw Four challenge. `challenge: false` is the victim simply
    /// accepting the draw, unchanged from pre-challenge behavior. `challenge: true` checks the
    /// ground truth captured when the card was played: correct challenge makes the offender draw
    /// 4 instead (the victim's own turn then proceeds normally, unaffected); incorrect challenge
    /// makes the challenger draw 6 (4 + 2 penalty) and lose their turn.
    func resolveWildDraw4Challenge(challenge: Bool) {
        guard let pending = pendingWildDraw4Challenge else { return }
        pendingWildDraw4Challenge = nil

        if !challenge {
            forceDraw(count: 4, onPlayerIndex: pending.victimIndex)
            advanceTurn(steps: 1, from: pending.victimIndex)
        } else if pending.hadMatchingColor {
            forceDraw(count: 4, onPlayerIndex: pending.playerIndex)
            hapticSuccess()
            showToast(L.t("game.challengeCorrect"))
        } else {
            forceDraw(count: 6, onPlayerIndex: pending.victimIndex)
            advanceTurn(steps: 1, from: pending.victimIndex)
            hapticError()
            showToast(L.t("game.challengeIncorrect"))
        }
        afterTurnMutation()
    }
}
