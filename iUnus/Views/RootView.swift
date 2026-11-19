import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = GameViewModel()
    @EnvironmentObject private var settings: SettingsViewModel
    @EnvironmentObject private var gameCenterManager: GameCenterManager
    @EnvironmentObject private var onlineMatchCoordinator: OnlineMatchCoordinator
    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: phaseIdentifier)
            .transition(.opacity)

            if showSplash {
                SplashView { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.4)) { showSplash = false } }
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .preferredColorScheme(settings.theme.colorScheme)
        .transaction { if reduceMotion { $0.disablesAnimations = true } }
        .onAppear {
            viewModel.configure(settings: settings)
            onlineMatchCoordinator.attach(gameViewModel: viewModel)
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
                gameCenterManager.authenticate()
            }
        }
        .onChange(of: scenePhase) { phase in
            viewModel.setSuspended(phase != .active)
        }
        .overlay(alignment: .bottom) {
            if viewModel.isOnlineUpdatePending {
                HStack {
                    ProgressView()
                    Text(onlineMatchCoordinator.statusMessage ?? L.t("online.saving"))
                        .font(.caption)
                    if onlineMatchCoordinator.canRetryUpdate && onlineMatchCoordinator.statusMessage != nil {
                        Button(L.t("common.retry")) { onlineMatchCoordinator.retryPendingUpdate() }
                    }
                }
                .padding().background(.regularMaterial).cornerRadius(12).padding()
            }
        }
        .alert(L.t("online.error"), isPresented: Binding(
            get: { onlineMatchCoordinator.statusMessage != nil && !viewModel.isOnlineUpdatePending },
            set: { if !$0 { onlineMatchCoordinator.statusMessage = nil } }
        )) {
            Button(L.t("settings.done")) { onlineMatchCoordinator.statusMessage = nil }
        } message: {
            Text(onlineMatchCoordinator.statusMessage ?? "")
        }
        .background {
            if let authViewController = gameCenterManager.authViewController {
                GameKitViewControllerPresenter(viewController: authViewController)
            }
        }
        .fullScreenCover(isPresented: $onlineMatchCoordinator.isPresentingMatchmaker) {
            TurnBasedMatchmakerView(minPlayers: 2, maxPlayers: 4, onDismiss: {
                onlineMatchCoordinator.isPresentingMatchmaker = false
            }, onError: { error in
                onlineMatchCoordinator.isPresentingMatchmaker = false
                onlineMatchCoordinator.statusMessage = error.localizedDescription
            })
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
