import SwiftUI

struct MenuView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject private var statsStore = MatchStatsStore.shared
    @EnvironmentObject private var gameCenterManager: GameCenterManager
    @EnvironmentObject private var onlineMatchCoordinator: OnlineMatchCoordinator
    @State private var opponentCount = 2
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showRules = false
    @State private var showSignInAlert = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.brandBackground, Color.brandSurface.opacity(0.6)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                titleBlock

                Spacer()

                VStack(spacing: 16) {
                    if viewModel.hasSavedGame {
                        continueButton
                    }
                    startCard
                }

                VStack(spacing: 12) {
                    menuButton(L.t("menu.multiplayer"), icon: "network") { openMultiplayer() }
                    menuButton(L.t("menu.rules"), icon: "book.closed.fill") { showRules = true }
                    menuButton(L.t("menu.settings"), icon: "gearshape.fill") { showSettings = true }
                    menuButton(L.t("menu.about"), icon: "info.circle.fill") { showAbout = true }
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showAbout) { AboutView() }
        .sheet(isPresented: $showRules) { RulesView() }
        .alert(L.t("menu.multiplayer.signInTitle"), isPresented: $showSignInAlert) {
            Button(L.t("settings.done"), role: .cancel) {}
        } message: {
            Text(L.t("menu.multiplayer.signInMessage"))
        }
    }

    private func openMultiplayer() {
        guard gameCenterManager.isAuthenticated else {
            gameCenterManager.authenticate()
            showSignInAlert = true
            return
        }
        onlineMatchCoordinator.isPresentingMatchmaker = true
    }

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text(L.t("menu.title"))
                .font(.system(size: 54, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(
                    LinearGradient(colors: [.brandPrimary, .brandSecondary], startPoint: .leading, endPoint: .trailing)
                )
                .shadow(color: Color.brandPrimary.opacity(0.25), radius: 12, y: 4)
            Text(L.t("menu.subtitle"))
                .font(.subheadline)
                .foregroundColor(.brandTextSecondary)
                .multilineTextAlignment(.center)

            if statsStore.stats.gamesPlayed > 0 {
                Text("\(String(format: L.t("stats.wins"), statsStore.stats.gamesWon)) · \(String(format: L.t("stats.streak"), statsStore.stats.currentStreak))")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.brandTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color.brandSurface)
                            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    )
                    .padding(.top, 10)
            }
        }
    }

    private var continueButton: some View {
        Button {
            viewModel.resumeSavedGame()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise.circle.fill")
                Text(L.t("menu.continueGame"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .font(.headline.weight(.bold))
            .foregroundColor(.brandPrimary)
            .frame(maxWidth: 260)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .strokeBorder(
                        LinearGradient(colors: [.brandPrimary, .brandSecondary], startPoint: .leading, endPoint: .trailing),
                        lineWidth: 2
                    )
            )
        }
    }

    private var startCard: some View {
        VStack(spacing: 14) {
            Text(L.t("menu.players"))
                .font(.headline)
                .foregroundColor(.brandTextPrimary)

            Picker(L.t("menu.players"), selection: $opponentCount) {
                ForEach(1...3, id: \.self) { n in
                    Text("\(n)").tag(n)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 220)

            Button {
                viewModel.startNewGame(opponentCount: opponentCount)
            } label: {
                Text(L.t("menu.startGame"))
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: 260)
                    .padding(.vertical, 16)
                    .background(
                        Capsule().fill(
                            LinearGradient(colors: [.brandPrimary, .brandSecondary], startPoint: .leading, endPoint: .trailing)
                        )
                    )
                    .shadow(color: Color.brandPrimary.opacity(0.4), radius: 14, y: 6)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.brandSurface.opacity(0.7))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        )
    }

    private func menuButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.14))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .foregroundColor(.brandPrimary)
                        .font(.subheadline.weight(.semibold))
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.brandTextSecondary.opacity(0.6))
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(.brandTextPrimary)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.brandSurface)
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
            )
        }
        .frame(maxWidth: 280)
    }
}
