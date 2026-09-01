import SwiftUI

struct CardView: View {
    let card: Card
    var faceDown: Bool = false
    var width: CGFloat = 70

    private var height: CGFloat { width * 1.5 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.14)
                .fill(faceDown ? Color.black : card.effectiveColor.displayColor)
                .overlay(
                    RoundedRectangle(cornerRadius: width * 0.14)
                        .stroke(Color.white.opacity(0.85), lineWidth: 2.5)
                        .padding(3)
                )
                .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 2)

            if faceDown {
                Circle()
                    .fill(Color.brandPrimary)
                    .frame(width: width * 0.5)
                    .overlay(Text("iU").font(.system(size: width * 0.22, weight: .heavy, design: .rounded)).foregroundColor(.white))
            } else {
                Ellipse()
                    .fill(Color.white.opacity(0.92))
                    .frame(width: width * 0.62, height: height * 0.42)
                    .rotationEffect(.degrees(-25))

                Text(card.value.symbol)
                    .font(.system(size: width * 0.34, weight: .heavy, design: .rounded))
                    .foregroundColor(card.effectiveColor.displayColor)
                    .rotationEffect(.degrees(-25))
                    .minimumScaleFactor(0.5)

                cornerLabel
            }
        }
        .frame(width: width, height: height)
    }

    private var cornerLabel: some View {
        VStack {
            HStack {
                Text(card.value.symbol)
                    .font(.system(size: width * 0.16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            Spacer()
        }
        .padding(width * 0.1)
    }
}

struct CardBackView: View {
    var width: CGFloat = 70
    var body: some View {
        CardView(card: Card(color: .wild, value: .wild), faceDown: true, width: width)
    }
}
