import SwiftUI

struct RulesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(L.t("rules.summary"))
                    .font(.body)
                    .foregroundColor(.brandTextPrimary)
                    .padding()
            }
            .background(Color.brandBackground)
            .navigationTitle(L.t("rules.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.t("common.back")) { dismiss() }
                }
            }
        }
    }
}
