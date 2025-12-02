import SwiftUI

struct LanguageGeneralSettingsView: View {
    @Binding var languageCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Jezik")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Picker(
                "",
                selection: Binding(
                    get: { languageCode },
                    set: { newCode in
                        languageCode = newCode
                        if let lang = ApplicationLanguage(rawValue: newCode) {
                            Localization.shared.setLanguage(lang)
                        }
                    }
                )
            ) {
                Text("Hrvatski").tag("hr")
                Text("English").tag("en")
                Text("Deutsch").tag("de")
                Text("Français").tag("fr")
            }
            .pickerStyle(.segmented)

            Text("Promjena jezika primijenit će se kasnije na tekstove u aplikaciji.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}
