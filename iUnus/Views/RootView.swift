import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = GameViewModel()
    @EnvironmentObject private var settings: SettingsViewModel
    @EnvironmentObject private var gameCenterManager: GameCenterManager
    @EnvironmentObject private var onlineMatchCoordinator: OnlineMatchCoordinator
    @State private var showSplash = true

    var body: some View {
        ZStack {
            Group {
                switch viewModel.phase {
                case .menu:
                    MenuView(viewModel: viewModel)
                case .dealing, .playing, .choosingColor:
                    GameView(viewModel: viewModel)
                case .roundEnd:
                    RoundEndView(viewModel: viewModel)
                case .gameEnd:
                    GameEndView(viewModel: viewModel)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: phaseIdentifier)
            .transition(.opacity)

            if showSplash {
                SplashView { withAnimation(.easeInOut(duration: 0.4)) { showSplash = false } }
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .preferredColorScheme(settings.theme.colorScheme)
        .onAppear {
            viewModel.configure(settings: settings)
            onlineMatchCoordinator.attach(gameViewModel: viewModel)
            gameCenterManager.authenticate()
        }
        .background {
            if let authViewController = gameCenterManager.authViewController {
                GameKitViewControllerPresenter(viewController: authViewController)
            }
        }
        .fullScreenCover(isPresented: $onlineMatchCoordinator.isPresentingMatchmaker) {
            TurnBasedMatchmakerView(minPlayers: 2, maxPlayers: 4) {
                onlineMatchCoordinator.isPresentingMatchmaker = false
            }
            .ignoresSafeArea()
        }
    }

    private var phaseIdentifier: Int {
        switch viewModel.phase {
        case .menu: return 0
        case .dealing: return 1
        case .playing: return 2
        case .choosingColor: return 3
        case .roundEnd: return 4
        case .gameEnd: return 5
        }
    }
}
