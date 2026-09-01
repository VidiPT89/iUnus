import SwiftUI

struct ColorPickerSheet: View {
    let onChoose: (CardColor) -> Void

    private let options: [(CardColor, String)] = [
        (.red, "color.red"), (.yellow, "color.yellow"), (.green, "color.green"), (.blue, "color.blue")
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text(L.t("colorPicker.title"))
                .font(.title3.weight(.bold))
                .foregroundColor(.brandTextPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(options, id: \.0) { color, key in
                    Button {
                        onChoose(color)
                    } label: {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(color.displayColor)
                            .frame(height: 84)
                            .overlay(Text(L.t(key)).font(.headline).foregroundColor(.white))
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 28)
        .background(Color.brandSurface)
    }
}
