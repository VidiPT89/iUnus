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
