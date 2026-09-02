import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: SettingsViewModel
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        NavigationView {
            Form {
                Section(L.t("settings.language")) {
                    Picker(L.t("settings.language"), selection: $localization.language) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(L.t("settings.theme")) {
                    Picker(L.t("settings.theme"), selection: $settings.theme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(L.t(theme.titleKey)).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(L.t("settings.difficulty")) {
                    Picker(L.t("settings.difficulty"), selection: $settings.aiDifficulty) {
                        ForEach(AIDifficulty.allCases) { difficulty in
                            Text(L.t(difficulty.titleKey)).tag(difficulty)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(L.t("settings.aiSpeed")) {
                    Picker(L.t("settings.aiSpeed"), selection: $settings.aiSpeed) {
                        ForEach(AISpeed.allCases) { speed in
                            Text(L.t(speed.titleKey)).tag(speed)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(L.t("settings.ruleSet")) {
                    Picker(L.t("settings.ruleSet"), selection: $settings.ruleSet) {
                        ForEach(RuleSet.allCases) { ruleSet in
                            Text(L.t(ruleSet.titleKey)).tag(ruleSet)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(L.t(settings.ruleSet.subtitleKey))
                        .font(.footnote)
                        .foregroundColor(.brandTextSecondary)
                }
            }
            .navigationTitle(L.t("settings.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.t("settings.done")) { dismiss() }
                }
            }
        }
    }
}
