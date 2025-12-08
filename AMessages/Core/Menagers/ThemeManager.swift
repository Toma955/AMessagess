import SwiftUI

final class ThemeManager: ObservableObject {
    @Published var currentID: AppThemeID {
        didSet {
            saveToDefaults()
        }
    }

    var currentTheme: AppTheme {
        currentID.theme
    }

    init() {
        if let saved = Self.loadFromDefaults() {
            self.currentID = saved
        } else {
            self.currentID = .onlineGreen
        }
    }

    func selectTheme(index: Int) {
        if let id = AppThemeID(rawValue: index) {
            currentID = id
        }
    }

    // MARK: - UserDefaults

    private func saveToDefaults() {
        UserDefaults.standard.set(currentID.rawValue, forKey: "AppThemeID")
    }

    private static func loadFromDefaults() -> AppThemeID? {
        let raw = UserDefaults.standard.integer(forKey: "AppThemeID")
        return AppThemeID(rawValue: raw)
    }
}
