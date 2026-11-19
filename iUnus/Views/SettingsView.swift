import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: SettingsViewModel
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var statsStore = MatchStatsStore.shared
    @State private var confirmStatsReset = false

    var body: some View {
        NavigationStack {
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

                Section(L.t("settings.sound")) {
                    Toggle(L.t("settings.sound"), isOn: $settings.soundEnabled)
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

                Section(L.t("settings.stats")) {
                    statRow("settings.stats.played", statsStore.stats.gamesPlayed)
                    statRow("settings.stats.won", statsStore.stats.gamesWon)
                    statRow("settings.stats.bestStreak", statsStore.stats.bestStreak)
                    statRow("settings.stats.bestScore", statsStore.stats.bestScore)
                    Button(L.t("settings.stats.reset"), role: .destructive) { confirmStatsReset = true }
                        .disabled(statsStore.stats == MatchStats())
                }
            }
            .confirmationDialog(L.t("settings.stats.resetConfirm"), isPresented: $confirmStatsReset, titleVisibility: .visible) {
                Button(L.t("settings.stats.reset"), role: .destructive) { statsStore.reset() }
            }
            .navigationTitle(L.t("settings.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.t("settings.done")) { dismiss() }
                }
            }
        }
    }

    private func statRow(_ key: String, _ value: Int) -> some View {
        LabeledContent(L.t(key)) {
            Text("\(value)").monospacedDigit()
        }
    }
}
