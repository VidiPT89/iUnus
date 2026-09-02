import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    @State private var markScale: CGFloat = 0.6
    @State private var markOpacity: Double = 0
    @State private var markRotation: Double = -12
    @State private var glowScale: CGFloat = 0.4
    @State private var glowOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 14
    @State private var shimmerPhase: CGFloat = -0.6
    @State private var creditsOpacity: Double = 0

    private let markAnimation = Animation.spring(response: 0.62, dampingFraction: 0.68)
    private let dismissDelay: TimeInterval = 2.2

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color.brandSurface, Color.brandBackground],
                center: .center,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.brandPrimary.opacity(0.55), Color.brandPrimary.opacity(0)],
                                    center: .center, startRadius: 4, endRadius: 90
                                )
                            )
                            .frame(width: 180, height: 180)
                            .scaleEffect(glowScale)
                            .opacity(glowOpacity)

                        Circle()
                            .fill(
                                LinearGradient(colors: [.brandPrimary, .brandSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text("iU")
                                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: Color.brandPrimary.opacity(0.5), radius: 18, y: 8)
                    }
                    .scaleEffect(markScale)
                    .opacity(markOpacity)
                    .rotationEffect(.degrees(markRotation))

                    Text(L.t("menu.title"))
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(
                            LinearGradient(colors: [.brandPrimary, .brandSecondary], startPoint: .leading, endPoint: .trailing)
                        )
                        .overlay(shimmerOverlay)
                        .opacity(titleOpacity)
                        .offset(y: titleOffset)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text(L.t("splash.developedBy"))
                        .font(.footnote)
                        .foregroundColor(.brandTextSecondary)
                    Text("David Arsénio Martins")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.brandTextPrimary)

                    VStack(spacing: 2) {
                        Text(L.t("splash.website"))
                        Text(L.t("splash.github"))
                    }
                    .font(.caption2)
                    .foregroundColor(.brandTextSecondary)
                    .padding(.top, 6)
                }
                .multilineTextAlignment(.center)
                .opacity(creditsOpacity)
                .padding(.bottom, 36)
            }
        }
        .onAppear { runEntrance() }
    }

    private var shimmerOverlay: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [.clear, .white.opacity(0.55), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: proxy.size.width * 0.5)
            .offset(x: proxy.size.width * shimmerPhase)
            .blendMode(.plusLighter)
        }
        .mask(
            Text(L.t("menu.title"))
                .font(.system(size: 38, weight: .black, design: .rounded))
                .tracking(1.5)
        )
    }

    private func runEntrance() {
        withAnimation(markAnimation) {
            markScale = 1.0
            markOpacity = 1.0
            markRotation = 0
        }
        withAnimation(.easeOut(duration: 0.9).delay(0.05)) {
            glowScale = 1.0
            glowOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.22)) {
            titleOpacity = 1.0
            titleOffset = 0
        }
        withAnimation(.easeInOut(duration: 0.9).delay(0.35)) {
            shimmerPhase = 1.4
        }
        withAnimation(.easeIn(duration: 0.5).delay(0.4)) {
            creditsOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
            onFinished()
        }
    }
}
