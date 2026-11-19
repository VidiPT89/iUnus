import XCTest
import SwiftUI
@testable import iUnus

@MainActor
final class LayoutTests: XCTestCase {
    func testMenuLayout() async throws {
        let settings = SettingsViewModel()
        let content = MenuView(viewModel: GameViewModel())
            .environmentObject(settings)
            .environmentObject(GameCenterManager())
            .environmentObject(OnlineMatchCoordinator())
        let size = CGSize(width: 375, height: 812)
        let host = UIHostingController(rootView: content)
        host.overrideUserInterfaceStyle = .dark
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        try await Task.sleep(nanoseconds: 100_000_000)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = "menu-dark"
        attachment.lifetime = .keepAlways
        add(attachment)
        window.isHidden = true
    }

    func testTableLayouts() async throws {
        for (name, size, dark, choosingDraw) in [
            ("small-phone", CGSize(width: 320, height: 568), false, true),
            ("phone-table", CGSize(width: 375, height: 667), false, false),
            ("phone-draw-choice", CGSize(width: 375, height: 667), true, true),
            ("ipad-table", CGSize(width: 768, height: 1024), true, false)
        ] {
            let game = GameViewModel()
            var human = Player(name: "You", kind: .human)
            human.hand = [.init(color: .red, value: .number(3)), .init(color: .red, value: .reverse),
                          .init(color: .yellow, value: .number(8)), .init(color: .green, value: .drawTwo),
                          .init(color: .blue, value: .number(7)), .init(color: .wild, value: .wild)]
            game.players = [human] + (1...3).map { index in
                var opponent = Player(name: "Opponent \(index)", kind: .ai)
                opponent.hand = (0..<7).map { _ in Card(color: .blue, value: .number(1)) }
                return opponent
            }
            game.deck.startDiscard(with: Card(color: .red, value: .number(7)))
            game.phase = .playing
            if choosingDraw { game.drawnCardToPlayID = human.hand[0].id }
            let host = UIHostingController(rootView: GameView(viewModel: game))
            host.overrideUserInterfaceStyle = dark ? .dark : .light
            let window = UIWindow(frame: CGRect(origin: .zero, size: size))
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.frame = window.bounds
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            try await Task.sleep(nanoseconds: 100_000_000)
            let image = UIGraphicsImageRenderer(size: size).image { _ in
                host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
            window.isHidden = true
        }
    }
}
