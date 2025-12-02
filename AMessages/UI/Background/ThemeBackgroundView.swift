import SwiftUI

/// Bira pozadinu na temelju session.selectedTheme (AppThemeID)
struct ThemeBackgroundView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        // selectedTheme je String (npr. "0", "1", "2" ...)
        // pretvaramo ga u Int za AppThemeID.fromStored(_:)
        let rawInt = Int(session.selectedTheme) ?? 0
        let themeId = AppThemeID.fromStored(rawInt)

        Group {
            switch themeId {
            case .onlineGreen:
                // tvoj default “lava” background
                BackgroundView()

            case .oceanBlue:
                // ovdje ide tvoja plava tema (ako imaš taj view)
                OceanBackgroundView()

            case .violetNight:
                // recimo nordijska/aurora tema
                NordicBackgroundView()

            case .goldenSunset:
                OrientBackgroundView()

            case .warmOrange:
                GreenParadiseBackgroundView()

            case .alertRed:
                NebulaBackgroundView()

            case .pureBlack:
                Color.black

            case .pureWhite:
                Color.white
            }
        }
        .ignoresSafeArea()
    }
}
