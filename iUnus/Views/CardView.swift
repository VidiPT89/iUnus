import SwiftUI

struct CardView: View {
    let card: Card
    var faceDown: Bool = false
    var width: CGFloat = 70

    private var height: CGFloat { width * 1.5 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.16)
                .fill(
                    faceDown
                        ? AnyShapeStyle(LinearGradient(colors: [Color.black, Color.black.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(LinearGradient(colors: [card.effectiveColor.displayColor, card.effectiveColor.displayColor.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: width * 0.16)
                        .stroke(Color.white.opacity(0.9), lineWidth: width * 0.035)
                        .padding(width * 0.045)
                )
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)

            if faceDown {
                Circle()
                    .fill(Color.brandPrimary)
                    .frame(width: width * 0.5)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                    )
                    .overlay(Text("iU").font(.system(size: width * 0.22, weight: .heavy, design: .rounded)).foregroundColor(.white))
            } else {
                Ellipse()
                    .fill(Color.white.opacity(0.94))
                    .frame(width: width * 0.64, height: height * 0.44)
                    .rotationEffect(.degrees(-22))
                    .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)

                Text(card.value.symbol)
                    .font(.system(size: width * 0.34, weight: .heavy, design: .rounded))
                    .foregroundColor(card.effectiveColor.displayColor)
                    .rotationEffect(.degrees(-22))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                cornerLabel(alignment: .topLeading)
                cornerLabel(alignment: .bottomTrailing)
            }
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(faceDown ? L.t("card.faceDown") : card.accessibilityLabel)
    }

    /// Yellow cards need dark corner text to stay readable; every other face color reads fine on white/black text.
    private var cornerTextColor: Color {
        card.effectiveColor == .yellow ? .black : .white
    }

    private func cornerLabel(alignment: Alignment) -> some View {
        Text(card.value.symbol)
            .font(.system(size: width * 0.16, weight: .bold))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .foregroundColor(cornerTextColor)
            .rotationEffect(alignment == .bottomTrailing ? .degrees(180) : .degrees(0))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .padding(width * 0.1)
    }
}

struct CardBackView: View {
    var width: CGFloat = 70
    var body: some View {
        CardView(card: Card(color: .wild, value: .wild), faceDown: true, width: width)
    }
}
