import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    @State private var markScale: CGFloat = 0.7
    @State private var markOpacity: Double = 0
    @State private var creditsOpacity: Double = 0

    private let markAnimation = Animation.spring(response: 0.55, dampingFraction: 0.72)
    private let dismissDelay: TimeInterval = 2.0

    var body: some View {
        ZStack {
            Color.brandBackground.ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.brandPrimary)
                            .frame(width: 96, height: 96)
                            .overlay(
                                Text("iU")
                                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                            )
                    }
                    .scaleEffect(markScale)
                    .opacity(markOpacity)

                    Text(L.t("menu.title"))
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.brandPrimary, .brandSecondary], startPoint: .leading, endPoint: .trailing)
                        )
                        .opacity(markOpacity)
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
        .onAppear {
            withAnimation(markAnimation) {
                markScale = 1.0
                markOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.25)) {
                creditsOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
                onFinished()
            }
        }
    }
}
