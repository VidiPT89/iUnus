import SwiftUI

struct WildDraw4ChallengeSheet: View {
    let offenderName: String
    let onChallenge: () -> Void
    let onAccept: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(L.t("wildDraw4.title"))
                .font(.title3.weight(.bold))
                .foregroundColor(.brandTextPrimary)

            Text(String(format: L.t("wildDraw4.body"), offenderName))
                .font(.subheadline)
                .foregroundColor(.brandTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                Button(action: onChallenge) {
                    Text(L.t("wildDraw4.challenge"))
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.brandPrimary))
                }

                Button(action: onAccept) {
                    Text(L.t("wildDraw4.accept"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.brandTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 28)
        .background(Color.brandSurface)
    }
}
