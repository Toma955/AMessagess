import SwiftUI

struct ThemeGeneralSettingsView: View {
    @Binding var themeSelection: AppThemeID
    @ObservedObject private var localization = Localization.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localization.text(.generalThemeTitle))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            ThemeSelectorHorizontal(selection: $themeSelection)

            Text(localization.text(.generalThemeDescription))
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}
