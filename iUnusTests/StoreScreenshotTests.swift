import XCTest
import SwiftUI
@testable import iUnus

/// Renders the App Store screenshots. Skipped unless the runner passes a destination folder:
/// `TEST_RUNNER_STORE_SHOTS_DIR=/path xcodebuild test -only-testing:iUnusTests/StoreScreenshotTests`.
@MainActor
final class StoreScreenshotTests: XCTestCase {
    private struct Device {
        let name: String
        let points: CGSize
        let scale: CGFloat
        let insets: UIEdgeInsets
    }

    private let devices = [
        Device(name: "iphone", points: CGSize(width: 402, height: 874), scale: 3,
               insets: UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0)),
        Device(name: "ipad", points: CGSize(width: 1032, height: 1376), scale: 2,
               insets: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0))
    ]

    func testStoreScreenshots() async throws {
        guard let dir = ProcessInfo.processInfo.environment["STORE_SHOTS_DIR"] else {
            throw XCTSkip("STORE_SHOTS_DIR not set")
        }
        let localization = LocalizationManager.shared
        let previousLanguage = localization.language
        let previousStats = UserDefaults.standard.data(forKey: "app.matchStats")
        defer {
            localization.language = previousLanguage
            UserDefaults.standard.set(previousStats, forKey: "app.matchStats")
        }
        MatchStatsStore.shared.reset()
        for won in [true, true, false, true, true, true, false, true, true, true, true, false, true, true] {
            MatchStatsStore.shared.recordGameEnd(humanWon: won, humanScore: won ? 512 : 230)
        }

        for (language, code) in [(AppLanguage.english, "en"), (AppLanguage.portuguese, "pt")] {
            localization.language = language
            for device in devices {
                let screens: [(String, AnyView, UIUserInterfaceStyle, Double)] = [
                    ("1-table", AnyView(GameView(viewModel: tableGame())), .dark, 0.3),
                    ("2-menu", AnyView(menu()), .dark, 0.3),
                    ("3-round", AnyView(RoundEndView(viewModel: roundEndGame())), .dark, 1.4),
                    ("4-table-light", AnyView(GameView(viewModel: tableGame(stack: true))), .light, 0.3),
                    ("5-settings", AnyView(SettingsView().environmentObject(SettingsViewModel())), .dark, 0.5),
                    ("6-win", AnyView(GameEndView(viewModel: gameEndGame()).environmentObject(OnlineMatchCoordinator())), .dark, 2.0)
                ]
                for (name, view, style, wait) in screens {
                    let image = try await render(view, device: device, style: style, wait: wait)
                    let url = URL(fileURLWithPath: dir).appendingPathComponent("\(code)-\(device.name)-\(name).png")
                    try XCTUnwrap(image.pngData()).write(to: url)
                }
            }
        }
    }

    private func render(_ view: AnyView, device: Device, style: UIUserInterfaceStyle, wait: Double) async throws -> UIImage {
        let host = UIHostingController(rootView: view)
        host.overrideUserInterfaceStyle = style
        host.additionalSafeAreaInsets = device.insets
        let window = UIWindow(frame: CGRect(origin: .zero, size: device.points))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
        let format = UIGraphicsImageRendererFormat()
        format.scale = device.scale
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: device.points, format: format).image { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
        window.isHidden = true
        return image
    }

    private func menu() -> some View {
        MenuView(viewModel: GameViewModel())
            .environmentObject(SettingsViewModel())
            .environmentObject(GameCenterManager())
            .environmentObject(OnlineMatchCoordinator())
    }

    private func seats(_ counts: [Int]) -> [Player] {
        var human = Player(name: L.t("player.you"), kind: .human)
        human.hand = [.init(color: .red, value: .number(3)), .init(color: .red, value: .skip),
                      .init(color: .yellow, value: .number(7)), .init(color: .green, value: .number(5)),
                      .init(color: .green, value: .drawTwo), .init(color: .blue, value: .number(7)),
                      .init(color: .blue, value: .reverse), .init(color: .wild, value: .wild)]
        let opponents = counts.enumerated().map { index, count -> Player in
            var opponent = Player(name: String(format: L.t("player.opponent"), index + 1), kind: .ai)
            opponent.hand = (0..<count).map { _ in Card(color: .blue, value: .number(1)) }
            return opponent
        }
        return [human] + opponents
    }

    private func tableGame(stack: Bool = false) -> GameViewModel {
        let game = GameViewModel()
        game.players = seats([5, 2, 6])
        game.deck.startDiscard(with: stack ? Card(color: .green, value: .drawTwo) : Card(color: .red, value: .number(7)))
        game.phase = .playing
        game.activeRuleSet = stack ? .houseRules : .official
        if stack {
            game.pendingDrawStack = 2
            game.direction = .counterClockwise
        }
        return game
    }

    private func roundEndGame() -> GameViewModel {
        let game = GameViewModel()
        game.players = seats([4, 1, 6])
        for (index, score) in [312, 145, 268, 90].enumerated() { game.players[index].totalScore = score }
        game.players[0].hand = []
        game.roundWinnerID = game.players[0].id
        game.lastRoundPoints = 96
        game.phase = .roundEnd
        return game
    }

    private func gameEndGame() -> GameViewModel {
        let game = GameViewModel()
        game.players = seats([3, 2, 5])
        for (index, score) in [512, 301, 377, 120].enumerated() { game.players[index].totalScore = score }
        game.roundWinnerID = game.players[0].id
        game.gameWinnerID = game.players[0].id
        game.phase = .gameEnd
        return game
    }
}
