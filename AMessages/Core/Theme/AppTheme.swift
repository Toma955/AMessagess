import SwiftUI

// Jedna tema aplikacije
struct AppTheme {
    let name: String

    let background: Color        // pozadina cijele app
    let panelBackground: Color   // pozadine prozora / panela
    let accent: Color            // glavna naglašena boja (tipke, aktivni elementi)
    let accentSoft: Color        // blaža varijanta accenta
    let textPrimary: Color       // primarni tekst
    let textSecondary: Color     // sekundarni tekst

    let highlightGradient: LinearGradient   // gradient za header/badge itd.
}

// 8 tema – 6 “staklenih” + čista crna i bijela
enum AppThemeID: Int, CaseIterable, Identifiable {
    case onlineGreen = 0
    case oceanBlue
    case violetNight
    case goldenSunset
    case warmOrange
    case alertRed
    case pureBlack
    case pureWhite

    var id: Int { rawValue }
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
        case .pureBlack:    return "Black"
        case .pureWhite:    return "White"
        }
    }

    var theme: AppTheme {
        switch self {
        // 1) ZELENA “ONLINE”
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

        // 2) PLAVA “OCEAN”
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

        // 3) LJUBIČASTA “VIOLET NIGHT”
        case .violetNight:
            return AppTheme(
                name: "Violet",
                background: Color(red: 0.04, green: 0.02, blue: 0.08),
                panelBackground: Color(red: 0.06, green: 0.03, blue: 0.12),
                accent: Color(red: 0.65, green: 0.45, blue: 1.0),
                accentSoft: Color(red: 0.45, green: 0.25, blue: 0.8),
                textPrimary: .white,
                textSecondary: .white.opacity(0.6),
                highlightGradient: LinearGradient(
                    colors: [
                        Color(red: 0.65, green: 0.45, blue: 1.0),
                        Color(red: 0.45, green: 0.25, blue: 0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

        // 4) NARANČASTO-ZLATNA “SUNSET”
        case .goldenSunset:
            return AppTheme(
                name: "Sunset",
                background: Color(red: 0.08, green: 0.04, blue: 0.02),
                panelBackground: Color(red: 0.10, green: 0.05, blue: 0.03),
                accent: Color(red: 1.0, green: 0.65, blue: 0.25),
                accentSoft: Color(red: 0.9, green: 0.45, blue: 0.20),
                textPrimary: .white,
                textSecondary: .white.opacity(0.6),
                highlightGradient: LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.65, blue: 0.25),
                        Color(red: 0.9, green: 0.45, blue: 0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

        // 5) TOPLA NARANČASTA “WARM”
        case .warmOrange:
            return AppTheme(
                name: "Warm",
                background: Color(red: 0.10, green: 0.04, blue: 0.02),
                panelBackground: Color(red: 0.12, green: 0.05, blue: 0.03),
                accent: Color(red: 1.0, green: 0.55, blue: 0.20),
                accentSoft: Color(red: 0.9, green: 0.35, blue: 0.15),
                textPrimary: .white,
                textSecondary: .white.opacity(0.6),
                highlightGradient: LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.55, blue: 0.20),
                        Color(red: 0.9, green: 0.35, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

        // 6) CRVENA “ALERT”
        case .alertRed:
            return AppTheme(
                name: "Alert",
                background: Color(red: 0.10, green: 0.02, blue: 0.02),
                panelBackground: Color(red: 0.12, green: 0.03, blue: 0.03),
                accent: Color(red: 1.0, green: 0.35, blue: 0.35),
                accentSoft: Color(red: 0.8, green: 0.15, blue: 0.20),
                textPrimary: .white,
                textSecondary: .white.opacity(0.6),
                highlightGradient: LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.35, blue: 0.35),
                        Color(red: 0.8, green: 0.15, blue: 0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

        // 7) ČISTA CRNA
        case .pureBlack:
            return AppTheme(
                name: "Black",
                background: .black,
                panelBackground: .black,
                accent: .white,
                accentSoft: .gray,
                textPrimary: .white,
                textSecondary: .white.opacity(0.6),
                highlightGradient: LinearGradient(
                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

        // 8) ČISTA BIJELA
        case .pureWhite:
            return AppTheme(
                name: "White",
                background: .white,
                panelBackground: Color(white: 0.97),
                accent: .black,
                accentSoft: .gray,
                textPrimary: .black,
                textSecondary: .black.opacity(0.6),
                highlightGradient: LinearGradient(
                    colors: [.black.opacity(0.25), .black.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    /// Helper za čitanje iz spremljenog Int-a
    static func fromStored(_ raw: Int) -> AppThemeID {
        AppThemeID(rawValue: raw) ?? .onlineGreen
    }
}
