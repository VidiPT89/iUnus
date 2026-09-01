import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "suit.club.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.brandPrimary)

                Text(L.t("about.developedBy"))
                    .font(.subheadline)
                    .foregroundColor(.brandTextSecondary)
                Text(L.t("about.author"))
                    .font(.title3.weight(.bold))
                    .foregroundColor(.brandTextPrimary)

                VStack(spacing: 14) {
                    Link(destination: URL(string: "https://ividi.dev/")!) {
                        linkRow(icon: "globe", title: L.t("about.website"), value: "ividi.dev")
                    }
                    Link(destination: URL(string: "https://github.com/VidiPT89/")!) {
                        linkRow(icon: "chevron.left.slash.chevron.right", title: L.t("about.github"), value: "VidiPT89")
                    }
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding()
            .navigationTitle(L.t("about.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.t("common.back")) { dismiss() }
                }
            }
        }
    }

    private func linkRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.brandPrimary)
            Text(title).foregroundColor(.brandTextPrimary)
            Spacer()
            Text(value).foregroundColor(.brandSecondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.brandSurface))
        .frame(maxWidth: 320)
    }
}
