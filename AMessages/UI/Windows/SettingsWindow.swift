import SwiftUI

enum ConnectionStatus {
    case ok
    case failed
}

struct SettingsWindow: View {
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var session: SessionManager

    // promatramo lokalizaciju da se UI refresha kad se promijeni jezik
    @ObservedObject private var localization = Localization.shared

    // MARK: - Sidebar sekcije

    enum SettingsSection: String, CaseIterable, Identifiable {
        case general
        case network
        case security
        case files
        case widgets
        case about

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .general:  return "slider.horizontal.3"
            case .network:  return "antenna.radiowaves.left.and.right"
            case .security: return "lock.shield"
            case .files:    return "doc.on.doc"
            case .widgets:  return "square.grid.2x2"
            case .about:    return "info.circle"
            }
        }

        // ključ za prijevod naziva sekcije
        var localizationKey: LKey {
            switch self {
            case .general:  return .settingsGeneral
            case .network:  return .settingsNetwork
            case .security: return .settingsSecurity
            case .files:    return .settingsFiles
            case .widgets:  return .settingsWidgets
            case .about:    return .settingsAbout
            }
        }
    }

    enum SizeMode {
        case normalSidebar      // 1 prozor
        case compactSidebar     // 2 prozora
        case bottomBar          // 3+ prozora
    }

    // MARK: - State

    @State private var selectedSection: SettingsSection = .general

    // GENERAL
    @State private var themeSelection: AppThemeID = .onlineGreen
    @State private var languageCode: String = Localization.shared.currentLanguage.rawValue
    @State private var soundEnabled: Bool = true
    @State private var notificationsEnabled: Bool = true

    // NETWORK
    @State private var serverText: String = ""
    @State private var isTestingConnection: Bool = false
    @State private var connectionStatus: ConnectionStatus? = nil
    @State private var connectionErrorText: String? = nil

    // SECURITY
    private let autoLockOptions: [Int] = [0, 1, 5, 15, 30]
    @State private var autoLockSelection: Int = 5
    @State private var panicRequiresPin: Bool = true

    // ABOUT
    private let appVersion: String = "0.1.0"
    private let buildNumber: String = "1"

    // MARK: - Layout / theme

    private var activeWindowCount: Int {
        windowManager.windows.filter { !$0.isDocked }.count
    }

    private var sizeMode: SizeMode {
        switch activeWindowCount {
        case 1:
            return .normalSidebar
        case 2:
            return .compactSidebar
        default:
            return .bottomBar
        }
    }

    
    private var settingsBackgroundColor: Color {
        let index = Int(session.selectedTheme) ?? 0
        switch index {
        case 0:
            return Color.black.opacity(0.12)
        case 1:
            return Color.black.opacity(0.35)
        case 2:
            return Color.black.opacity(0.80)
        case 3:
            return Color(red: 0.06, green: 0.10, blue: 0.25).opacity(0.82)
        case 4:
            return Color(red: 0.05, green: 0.18, blue: 0.10).opacity(0.82)
        case 5:
            return Color(red: 0.12, green: 0.05, blue: 0.20).opacity(0.82)
        default:
            return Color.black.opacity(0.35)
        }
    }

    private var closeButtonLabel: String {
        switch localization.currentLanguage {
        case .hr: return "Zatvori"
        case .en: return "Close"
        case .de: return "Schließen"
        case .fr: return "Fermer"
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            if sizeMode != .bottomBar {
                sidebar(sizeMode: sizeMode)
                Divider().background(Color.white.opacity(0.15))
            }

            ZStack {
                settingsBackgroundColor

                if sizeMode == .bottomBar {
                    VStack(spacing: 0) {
                        headerInline

                        contentArea
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .padding(.bottom, 6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                        bottomIconBar
                    }
                } else {
                    VStack(spacing: 0) {
                        contentArea
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
            }
        }
        .background(Color.black.opacity(0.2))
        .onAppear {
            // sync sa SessionManagerom
            serverText = session.serverAddress
            autoLockSelection = session.autoLockMinutes

            if let raw = Int(session.selectedTheme),
               let id = AppThemeID(rawValue: raw) {
                themeSelection = id
            } else {
                themeSelection = .onlineGreen
            }

            // jezik: povuci iz Localization (default .hr)
            languageCode = localization.currentLanguage.rawValue
        }
        .onChange(of: serverText) { newValue in
            session.serverAddress = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .onChange(of: autoLockSelection) { newValue in
            session.autoLockMinutes = newValue
        }
        .onChange(of: themeSelection) { newTheme in
            session.selectedTheme = String(newTheme.rawValue)
        }
        .onChange(of: languageCode) { newCode in
            if let lang = ApplicationLanguage(rawValue: newCode) {
                localization.setLanguage(lang)
            }
        }
    }

    // MARK: - Sidebar

    private func sidebar(sizeMode: SizeMode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if sizeMode == .normalSidebar {
                    Spacer()
                    Text(localization.text(.settingsTitle))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                } else {
                    Spacer()
                }
            }
            .padding(.bottom, 10)

            ForEach(SettingsSection.allCases) { section in
                Button {
                    withAnimation(.spring(response: 0.25,
                                          dampingFraction: 0.85)) {
                        selectedSection = section
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: section.systemImage)
                            .font(.system(size: 13, weight: .medium))

                        if sizeMode == .normalSidebar {
                            Text(localization.text(section.localizationKey))
                                .font(.system(size: 13, weight: .medium))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                selectedSection == section
                                ? Color.white.opacity(0.16)
                                : Color.white.opacity(0.04)
                            )
                    )
                    .foregroundColor(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            closeButtonSidebar(sizeMode: sizeMode)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: sizeMode == .compactSidebar ? 70 : 180)
        .background(
            Color.black.opacity(0.9)
        )
    }

    // MARK: - Header (3+ prozora)

    private var headerInline: some View {
        HStack {
            Spacer()
            Text(localization.text(.settingsTitle))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    // MARK: - Bottom bar (3+ prozora)

    private var bottomIconBar: some View {
        HStack(spacing: 10) {
            // X – crveni krug lijevo
            Button {
                windowManager.toggleSettings()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.red)
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)

            // ikone sekcija
            ForEach(SettingsSection.allCases) { section in
                Button {
                    withAnimation(.spring(response: 0.25,
                                          dampingFraction: 0.85)) {
                        selectedSection = section
                    }
                } label: {
                    ZStack {
                        if selectedSection == section {
                            Circle()
                                .fill(Color.white)
                            Image(systemName: section.systemImage)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                        } else {
                            Image(systemName: section.systemImage)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.9))
    }

    // MARK: - Zatvori gumb (1 i 2 prozora, u sidebaru)

    @ViewBuilder
    private func closeButtonSidebar(sizeMode: SizeMode) -> some View {
        switch sizeMode {
        case .normalSidebar:
            // 1 prozor: tekst + X
            Button {
                windowManager.toggleSettings()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                    Text(closeButtonLabel)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(red: 0.45, green: 0.10, blue: 0.10).opacity(0.95))
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

        case .compactSidebar:
            // 2 prozora: samo X
            Button {
                windowManager.toggleSettings()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(red: 0.45, green: 0.10, blue: 0.10).opacity(0.95))
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

        case .bottomBar:
            EmptyView()
        }
    }

    // MARK: - Content area

    @ViewBuilder
    private var contentArea: some View {
        switch selectedSection {
        case .general:
            SettingsGeneralView(
                themeSelection: $themeSelection,
                languageCode: $languageCode,
                soundEnabled: $soundEnabled,
                notificationsEnabled: $notificationsEnabled
            )

        case .network:
            SettingsNetworkView(
                serverText: $serverText,
                isTestingConnection: $isTestingConnection,
                connectionStatus: $connectionStatus,
                connectionErrorText: $connectionErrorText,
                runTestConnection: runTestConnection
            )

        case .security:
            SettingsSecurityView(
                autoLockSelection: $autoLockSelection,
                autoLockOptions: autoLockOptions,
                panicRequiresPin: $panicRequiresPin
            )

        case .files:
            SettingsCreateFilesView()

        case .widgets:
            SettingsWidgetView()

        case .about:
            SettingsAboutView(
                appVersion: appVersion,
                buildNumber: buildNumber
            )
        }
    }

    // MARK: - Test konekcije (simple)

    private func runTestConnection() {
        guard !session.serverAddress.isEmpty else { return }

        isTestingConnection = true
        connectionStatus = nil
        connectionErrorText = nil

        let addr = session.serverAddress.trimmingCharacters(in: .whitespacesAndNewlines)

        print("========== NETWORK TEST ==========")
        print("[PING] Uneseni server: '\(addr)'")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isTestingConnection = false

            if addr.lowercased().hasPrefix("http") {
                self.connectionStatus = .ok
                self.connectionErrorText = nil
                print("[PING] OK – format adrese izgleda ispravno.")
            } else {
                self.connectionStatus = .failed
                self.connectionErrorText = "Adresa servera mora početi s http:// ili https://"
                print("[PING] FAIL – čini se da format URL-a nije ispravan.")
            }
        }
    }
}
