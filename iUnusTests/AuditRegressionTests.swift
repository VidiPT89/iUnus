import XCTest
@testable import iUnus

@MainActor
final class AuditRegressionTests: XCTestCase {
    private struct DeckFixture: Encodable {
        let drawPile: [Card]
        let discardPile: [Card]
    }

    private func game(hand: [Card], other: [Card], top: Card, draw: [Card] = []) throws -> GameViewModel {
        let game = GameViewModel()
        var you = Player(name: "You", kind: .human)
        you.hand = hand
        var opponent = Player(name: "Opponent", kind: .human)
        opponent.hand = other
        game.players = [you, opponent]
        game.deck = try JSONDecoder().decode(Deck.self, from: JSONEncoder().encode(DeckFixture(drawPile: draw, discardPile: [top])))
        game.phase = .playing
        game.activeRuleSet = .official
        return game
    }

    func testFinalPenaltyCountsBeforeScoringAndCannotScoreTwice() throws {
        let last = Card(color: .red, value: .drawTwo)
        let game = try game(hand: [last], other: [.init(color: .blue, value: .number(3))],
                            top: .init(color: .red, value: .number(1)),
                            draw: [.init(color: .green, value: .number(5)), .init(color: .yellow, value: .number(9))])
        game.humanPlay(last)
        XCTAssertEqual(game.phase, .roundEnd)
        XCTAssertEqual(game.players[1].hand.count, 3)
        XCTAssertEqual(game.lastRoundPoints, 17)
        game.endRound(winnerIndex: 0)
        XCTAssertEqual(game.players[0].totalScore, 17)
        let restored = GameViewModel()
        restored.resumeSavedGame()
        XCTAssertEqual(restored.phase, .roundEnd)
        XCTAssertEqual(restored.players.first?.totalScore, 17)
    }

    func testFinalWildColorDecisionSurvivesResume() throws {
        let last = Card(color: .wild, value: .wildDrawFour)
        let game = try game(hand: [last], other: [.init(color: .blue, value: .number(3))], top: .init(color: .red, value: .number(1)),
                            draw: (1...4).map { .init(color: .yellow, value: .number($0)) })
        game.humanPlay(last)
        let restored = GameViewModel()
        restored.resumeSavedGame()
        XCTAssertEqual(restored.phase, .choosingColor(pendingCard: last))
        restored.chooseWildColor(.wild)
        XCTAssertEqual(restored.phase, .choosingColor(pendingCard: last))
        restored.chooseWildColor(.green)
        XCTAssertEqual(restored.phase, .roundEnd)
        XCTAssertEqual(restored.players[1].hand.count, 5)
        XCTAssertEqual(restored.lastRoundPoints, 13)
    }

    func testChallengeSurvivesResumeAndPunishesOffender() throws {
        let wild = Card(color: .wild, value: .wildDrawFour)
        let game = try game(hand: [wild, .init(color: .red, value: .number(3))],
                            other: [.init(color: .blue, value: .number(8))], top: .init(color: .red, value: .number(1)),
                            draw: (1...6).map { .init(color: .yellow, value: .number($0)) })
        game.humanPlay(wild)
        game.chooseWildColor(.green)
        XCTAssertNotNil(game.pendingWildDraw4Challenge)
        let restored = GameViewModel()
        restored.resumeSavedGame()
        XCTAssertEqual(restored.pendingWildDraw4Challenge, game.pendingWildDraw4Challenge)
        restored.resolveWildDraw4Challenge(challenge: true)
        XCTAssertNil(restored.pendingWildDraw4Challenge)
        XCTAssertEqual(restored.currentPlayerIndex, 1)
        XCTAssertEqual(restored.players[0].hand.count, 5)
        XCTAssertFalse(restored.players[0].hasCalledUno)
    }

    func testFailedChallengeDrawsSixAndSkipsVictim() throws {
        let wild = Card(color: .wild, value: .wildDrawFour)
        let game = try game(hand: [wild, .init(color: .blue, value: .number(3))],
                            other: [.init(color: .blue, value: .number(8))], top: .init(color: .red, value: .number(1)),
                            draw: (1...6).map { .init(color: .yellow, value: .number($0)) })
        game.humanPlay(wild)
        game.chooseWildColor(.green)
        game.resolveWildDraw4Challenge(challenge: true)
        XCTAssertEqual(game.players[1].hand.count, 7)
        XCTAssertEqual(game.currentPlayerIndex, 0)
    }

    func testInvalidMoveDoesNotCloseUnoWindow() throws {
        let card = Card(color: .blue, value: .number(3))
        let game = try game(hand: [card], other: [.init(color: .green, value: .number(8))], top: .init(color: .red, value: .number(1)))
        let pending = PendingUnoCatch(playerID: game.players[1].id, blockingPlayerIndex: 0)
        game.pendingUnoCatch = pending
        game.attemptPlay(card, playerIndex: 0)
        XCTAssertEqual(game.pendingUnoCatch, pending)
    }

    func testDrawingClearsPreviousUnoDeclaration() throws {
        let game = try game(hand: [.init(color: .blue, value: .number(3))], other: [.init(color: .green, value: .number(8))],
                            top: .init(color: .red, value: .number(1)), draw: [.init(color: .yellow, value: .number(2))])
        game.players[0].hasCalledUno = true
        game.humanDraw()
        XCTAssertFalse(game.players[0].hasCalledUno)
    }

    func testLegacySaveWithoutFinishOrderStillLoads() throws {
        let game = try game(hand: [.init(color: .blue, value: .number(3))], other: [.init(color: .green, value: .number(8))], top: .init(color: .red, value: .number(1)))
        game.saveProgressIfActive()
        let data = try XCTUnwrap(UserDefaults.standard.data(forKey: "app.savedGame"))
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        for key in ["roundFinishOrder", "phase", "ruleSet"] { json.removeValue(forKey: key) }
        let decoded = try JSONDecoder().decode(SavedGame.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertTrue(decoded.isValid)
        XCTAssertEqual(decoded.roundFinishOrder, [])
    }

    func testCorruptSaveRejectedWithoutCrashing() throws {
        let card = Card(color: .blue, value: .number(3))
        let game = try game(hand: [card], other: [.init(color: .green, value: .number(8))], top: .init(color: .red, value: .number(1)))
        game.players[1].hand.append(card)
        game.saveProgressIfActive()
        XCTAssertNil(GameSaveStore.load())
        game.currentPlayerIndex = 99
        game.saveProgressIfActive()
        XCTAssertNil(GameSaveStore.load())
    }

    func testRulesAreRestoredWithTheGame() throws {
        let game = try game(hand: [.init(color: .blue, value: .number(3))], other: [.init(color: .green, value: .number(8))], top: .init(color: .red, value: .number(1)))
        game.activeRuleSet = .houseRules
        game.saveProgressIfActive()
        let restored = GameViewModel()
        restored.resumeSavedGame()
        XCTAssertEqual(restored.activeRuleSet, .houseRules)
        XCTAssertFalse(restored.enforceWildDrawFourRestriction)
    }

    func testNewLocalGameClearsOnlineModeAndSuspension() {
        let game = GameViewModel()
        game.mode = .online
        game.onlineLocalPlayerID = UUID()
        game.isOnlineUpdatePending = true
        game.isSuspended = true
        game.startNewGame(opponentCount: 2)
        XCTAssertEqual(game.mode, .local)
        XCTAssertNil(game.onlineLocalPlayerID)
        XCTAssertFalse(game.isOnlineUpdatePending)
        XCTAssertFalse(game.isSuspended)
        game.returnToMenu()
    }

    func testSuspendingCancelsDelayedDealAndResumesSafely() async throws {
        let game = GameViewModel()
        game.startNewGame(opponentCount: 1)
        game.setSuspended(true)
        try await Task.sleep(nanoseconds: 1_400_000_000)
        XCTAssertEqual(game.phase, .dealing)
        game.setSuspended(false)
        XCTAssertEqual(game.phase, .playing)
        game.returnToMenu()
    }

    func testRuntimeLanguageSwitchAndCardValueEquality() {
        let localization = LocalizationManager.shared
        let previous = localization.language
        defer { localization.language = previous }
        localization.language = .portuguese
        XCTAssertEqual(L.t("color.red"), "Vermelho")
        localization.language = .english
        XCTAssertEqual(L.t("color.red"), "Red")
        let original = Card(color: .wild, value: .wild)
        var chosen = original
        chosen.chosenColor = .red
        XCTAssertNotEqual(original, chosen)
        XCTAssertEqual(Set([original, chosen]).count, 2)
    }

    func testOnlineSnapshotRejectsInvalidTurnAndDuplicateMapping() throws {
        let game = try game(hand: [.init(color: .blue, value: .number(3))], other: [.init(color: .green, value: .number(8))], top: .init(color: .red, value: .number(1)))
        game.mode = .online
        game.onlineLocalPlayerID = game.players[0].id
        game.onlineParticipantMapping = ["first": game.players[0].id, "second": game.players[1].id]
        var state = game.exportOnlineState()
        XCTAssertTrue(state.isValid)
        state.currentPlayerIndex = 99
        XCTAssertFalse(state.isValid)
        state.currentPlayerIndex = 0
        state.participantPlayerIDs["second"] = game.players[0].id
        XCTAssertFalse(state.isValid)
    }

    func testCompleteRoundsPreserveEveryCardAcrossRulesAndPlayerCounts() {
        // Whole-round exercise of the production engine, including draws, wild decisions,
        // challenges, recycling and players leaving the House Rules rotation.
        for rules in RuleSet.allCases {
            for count in [2, 4, 10] {
                for _ in 0..<5 {
                    let game = GameViewModel()
                    game.startNewGame(opponentCount: count - 1)
                    game.activeRuleSet = rules
                    game.turnWorkItem?.cancel()
                    game.phase = .playing
                    var turns = 0
                    while game.phase == .playing && turns < 5_000 {
                        if game.pendingWildDraw4Challenge != nil {
                            game.resolveWildDraw4Challenge(challenge: true)
                        } else {
                            let index = game.currentPlayerIndex
                            let hand = game.players[index].hand
                            let card: Card?
                            if let drawn = game.drawnCardToPlayID { card = hand.first { $0.id == drawn } }
                            else if game.pendingDrawStack > 0 { card = AIStrategy.chooseStackCard(hand: hand) }
                            else { card = AIStrategy.chooseCard(hand: hand, topCard: game.topCard!, opponentLowestCardCount: 2, enforceWildDrawFourRestriction: game.enforceWildDrawFourRestriction) }
                            if let card { game.attemptPlay(card, playerIndex: index) }
                            else { game.drawForCurrentPlayer() }
                            if case .choosingColor = game.phase { game.chooseWildColor(.red) }
                        }
                        game.turnWorkItem?.cancel()
                        let cards = game.players.flatMap(\.hand) + game.deck.drawPile + game.deck.discardPile
                        XCTAssertEqual(cards.count, 108)
                        XCTAssertEqual(Set(cards.map(\.id)).count, 108)
                        XCTAssertTrue(game.players.indices.contains(game.currentPlayerIndex))
                        turns += 1
                    }
                    XCTAssertEqual(game.phase, .roundEnd, "Failed to finish \(rules), \(count) players after \(turns) turns")
                    game.returnToMenu()
                }
            }
        }
    }
}
