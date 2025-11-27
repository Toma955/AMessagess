import SwiftUI

struct SettingsGeneralView: View {
    @EnvironmentObject var session: SessionManager

    @Binding var themeSelection: SettingsWindow.AppTheme
    @Binding var languageCode: String
    @Binding var soundEnabled: Bool
    @Binding var notificationsEnabled: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Općenito")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)

                // Tema
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tema")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Picker("Tema", selection: $themeSelection) {
                        ForEach(SettingsWindow.AppTheme.allCases) { theme in
                            Text(theme.label).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Jezik
                VStack(alignment: .leading, spacing: 8) {
                    Text("Jezik")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Picker("", selection: $languageCode) {
                        Text("Hrvatski").tag("hr")
                        Text("English").tag("en")
                    }
                    .pickerStyle(.segmented)

                    Text("Promjena jezika će se kasnije odnositi na sve tekstove u aplikaciji.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Zvuk
                Toggle(isOn: $soundEnabled) {
                    Text("Zvukovi obavijesti")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .toggleStyle(SwitchToggleStyle(tint: .orange))

                // Obavijesti
                Toggle(isOn: $notificationsEnabled) {
                    Text("Prikaži obavijesti o novim porukama")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .toggleStyle(SwitchToggleStyle(tint: .orange))
            }
            .padding(18)
        }
    }
}
