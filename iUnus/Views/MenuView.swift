import SwiftUI

struct MenuView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var opponentCount = 2
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showRules = false

    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 6) {
                    Text(L.t("menu.title"))
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.brandPrimary, .brandSecondary], startPoint: .leading, endPoint: .trailing)
                        )
                    Text(L.t("menu.subtitle"))
                        .font(.subheadline)
                        .foregroundColor(.brandTextSecondary)
                }

                Spacer()

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
                            .background(Capsule().fill(Color.brandPrimary))
                    }
                }

                VStack(spacing: 12) {
                    menuButton(L.t("menu.rules"), icon: "book.closed.fill") { showRules = true }
                    menuButton(L.t("menu.settings"), icon: "gearshape.fill") { showSettings = true }
                    menuButton(L.t("menu.about"), icon: "info.circle.fill") { showAbout = true }
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showAbout) { AboutView() }
        .sheet(isPresented: $showRules) { RulesView() }
    }

    private func menuButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(.brandTextPrimary)
            .padding()
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.brandSurface))
        }
        .frame(maxWidth: 280)
    }
}
