import SwiftUI

private struct RuleSection: Identifiable {
    let id: String
    let icon: String
    let titleKey: String
    let bodyKey: String
}

struct RulesView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss

    private let sections: [RuleSection] = [
        RuleSection(id: "turnOrder", icon: "arrow.triangle.turn.up.right.circle.fill", titleKey: "rules.turnOrder.title", bodyKey: "rules.turnOrder.body"),
        RuleSection(id: "specialCards", icon: "sparkles.rectangle.stack.fill", titleKey: "rules.specialCards.title", bodyKey: "rules.specialCards.body"),
        RuleSection(id: "unoCall", icon: "exclamationmark.bubble.fill", titleKey: "rules.unoCall.title", bodyKey: "rules.unoCall.body"),
        RuleSection(id: "scoring", icon: "trophy.fill", titleKey: "rules.scoring.title", bodyKey: "rules.scoring.body"),
        RuleSection(id: "house", icon: "house.fill", titleKey: "rules.house.title", bodyKey: "rules.house.body"),
        RuleSection(id: "online", icon: "network", titleKey: "rules.online.title", bodyKey: "rules.online.body")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(sections) { section in
                        sectionCard(section)
                    }
                }
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

    private func sectionCard(_ section: RuleSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .foregroundColor(.brandPrimary)
                Text(L.t(section.titleKey))
                    .font(.headline)
                    .foregroundColor(.brandTextPrimary)
            }
            Text(L.t(section.bodyKey))
                .font(.subheadline)
                .foregroundColor(.brandTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.brandSurface))
    }
}
