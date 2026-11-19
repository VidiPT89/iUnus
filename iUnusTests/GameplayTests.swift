import XCTest
@testable import iUnus

@MainActor
final class GameplayTests: XCTestCase {
    private func game() -> GameViewModel {
        let game = GameViewModel()
        var human = Player(name: "You", kind: .human)
        human.hand = [Card(color: .red, value: .number(3)), Card(color: .blue, value: .number(8))]
        var other = Player(name: "Other", kind: .human)
        other.hand = [Card(color: .green, value: .number(2))]
        game.players = [human, other]
        game.phase = .playing
        // Make the next randomly shuffled card playable without relying on chance.
        let next = game.deck.drawPile[0]
        game.deck.startDiscard(with: Card(color: next.value.isWild ? .yellow : next.color, value: .number(5)))
        return game
    }

    func testDrawOffersOnlyDrawnCardAndCannotDrawTwice() {
        let game = game()
        game.humanDraw()
        let drawn = game.players[0].hand.first { $0.id == game.drawnCardToPlayID }
        XCTAssertNotNil(drawn)
        XCTAssertEqual(game.currentPlayerIndex, 0)
        XCTAssertEqual(game.players[0].hand.count, 3)
        game.humanDraw()
        XCTAssertEqual(game.players[0].hand.count, 3)
        for card in game.players[0].hand {
            XCTAssertEqual(game.canLocalPlayerPlay(card), card.id == drawn?.id)
        }
        game.humanPassAfterDraw()
        XCTAssertNil(game.drawnCardToPlayID)
        XCTAssertEqual(game.currentPlayerIndex, 1)
        game.returnToMenu()
    }

    func testDrawChoiceCanBePlayedAndResumed() {
        let game = game()
        game.humanDraw()
        let id = game.drawnCardToPlayID
        let resumed = GameViewModel()
        resumed.resumeSavedGame()
        XCTAssertEqual(resumed.drawnCardToPlayID, id)
        guard let card = resumed.players[0].hand.first(where: { $0.id == id }) else {
            return XCTFail("Draw decision lost on resume")
        }
        resumed.humanPlay(card)
        if card.value.isWild { resumed.chooseWildColor(.green) }
        XCTAssertEqual(resumed.topCard?.id, id)
        XCTAssertNil(resumed.drawnCardToPlayID)
        resumed.returnToMenu()
        game.returnToMenu()
    }

    func testStackHighlightMatchesLegalResponseAcrossColors() {
        let game = game()
        game.deck.startDiscard(with: Card(color: .red, value: .drawTwo))
        let blueDraw = Card(color: .blue, value: .drawTwo)
        let redNumber = Card(color: .red, value: .number(7))
        game.players[0].hand = [blueDraw, redNumber]
        game.pendingDrawStack = 2
        XCTAssertTrue(game.canLocalPlayerPlay(blueDraw))
        XCTAssertFalse(game.canLocalPlayerPlay(redNumber))
        game.humanPlay(redNumber)
        XCTAssertEqual(game.players[0].hand.count, 2)
    }

    func testOlderSnapshotsDecodeWithoutDrawDecision() throws {
        let game = game()
        let saved = SavedGame(players: game.players, deck: game.deck, currentPlayerIndex: 0,
                              direction: .clockwise, pendingDrawStack: 0)
        let data = try JSONEncoder().encode(saved)
        let decoded = try JSONDecoder().decode(SavedGame.self, from: data)
        XCTAssertNil(decoded.drawnCardToPlayID)
    }

    func testOnlineSnapshotPreservesDrawChoice() throws {
        let game = game()
        game.mode = .online
        game.onlineLocalPlayerID = game.players[0].id
        game.humanDraw()
        let state = try JSONDecoder().decode(OnlineMatchState.self, from: JSONEncoder().encode(game.exportOnlineState()))
        XCTAssertNotNil(state.drawnCardToPlayID)
        XCTAssertEqual(state.currentPlayerIndex, 0)
    }

    func testQuittingDuringDealDoesNotRestartGame() async throws {
        let game = GameViewModel()
        game.startNewGame(opponentCount: 2)
        game.returnToMenu()
        try await Task.sleep(nanoseconds: 1_500_000_000)
        XCTAssertEqual(game.phase, .menu)
        XCTAssertTrue(game.players.isEmpty)
    }

    func testReverseSkipsWithTwoRemainingHousePlayers() {
        let settings = SettingsViewModel()
        let previous = settings.ruleSet
        defer { settings.ruleSet = previous }
        settings.ruleSet = .houseRules
        let game = game()
        game.configure(settings: settings)
        var third = Player(name: "Third", kind: .human)
        third.hand = [Card(color: .yellow, value: .number(1))]
        game.players.append(third)
        let finish = Card(color: .red, value: .number(5))
        game.players[0].hand = [finish]
        game.deck.startDiscard(with: Card(color: .red, value: .number(2)))
        game.humanPlay(finish)
        XCTAssertEqual(game.currentPlayerIndex, 1)
        let reverse = Card(color: .red, value: .reverse)
        game.players[1].hand = [reverse, Card(color: .green, value: .number(1))]
        game.attemptPlay(reverse, playerIndex: 1)
        XCTAssertEqual(game.currentPlayerIndex, 1)
    }
}
