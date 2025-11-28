import SwiftUI

struct AppTheme {
    let name: String

    let background: Color
    let panelBackground: Color
    let accent: Color
    let accentSoft: Color
    let textPrimary: Color
    let textSecondary: Color

    let highlightGradient: LinearGradient
}

enum AppThemeID: Int, CaseIterable {
    case onlineGreen = 0
    case oceanBlue
    case violetNight
    case goldenSunset
    case warmOrange
    case alertRed
}

extension AppThemeID {
    var displayName: String {
        switch self {
        case .onlineGreen:  return "Online"
        case .oceanBlue:    return "Ocean"
        case .violetNight:  return "Violet"
        case .goldenSunset: return "Sunset"
        case .warmOrange:   return "Warm"
        case .alertRed:     return "Alert"
        }
    }

    var theme: AppTheme {
        switch self {
        case .onlineGreen:
            return AppTheme(
                name: "Online",
                background: Color.black.opacity(0.95),
                panelBackground: Color.black.opacity(0.90),
                accent: Color(red: 0.20, green: 0.85, blue: 0.45),
                accentSoft: Color(red: 0.10, green: 0.55, blue: 0.30),
                textPrimary: .white,
                textSecondary: .white.opacity(0.6),
                highlightGradient: LinearGradient(
                    colors: [
                        Color(red: 0.20, green: 0.85, blue: 0.45),
                        Color(red: 0.10, green: 0.55, blue: 0.30)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

        case .oceanBlue:
            return AppTheme(
                name: "Ocean",
                background: Color(red: 0.04, green: 0.06, blue: 0.10),
                panelBackground: Color(red: 0.05, green: 0.07, blue: 0.12),
                accent: Color(red: 0.25, green: 0.70, blue: 0.90),
                accentSoft: Color(red: 0.15, green: 0.40, blue: 0.80),
                textPrimary: .white,
                textSecondary: .white.opacity(0.6),
                highlightGradient: LinearGradient(
                    colors: [
                        Color(red: 0.25, green: 0.70, blue: 0.90),
                        Color(red: 0.15, green: 0.40, blue: 0.80)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

        // možeš kasnije popuniti ostale (violetNight, goldenSunset, warmOrange, alertRed)
        default:
            return AppThemeID.onlineGreen.theme
        }
    }
}
