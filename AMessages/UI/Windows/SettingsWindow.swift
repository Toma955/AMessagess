import SwiftUI

struct SettingsWindow: View {
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var session: SessionManager

    // MARK: - Sidebar sekcije

    enum SettingsSection: String, CaseIterable, Identifiable {
        case general
        case network
        case security
        case files
        case widgets
        case about

        var id: String { rawValue }

        var title: String {
            switch self {
            case .general:  return "Općenito"
            case .network:  return "Internet"
            case .security: return "Sigurnost"
            case .files:    return "Datoteke"
            case .widgets:  return "Widgeti"
            case .about:    return "O aplikaciji"
            }
        }

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
    }

    enum AppTheme: String, CaseIterable, Identifiable {
        case system
        case dark
        case light
        case lava

        var id: String { rawValue }

        var label: String {
            switch self {
            case .system: return "System"
            case .dark:   return "Dark"
            case .light:  return "Light"
            case .lava:   return "Lava"
            }
        }
    }

    enum ConnectionStatus {
        case ok
        case failed
    }

    // MARK: - State

    @State private var selectedSection: SettingsSection = .general

    // GENERAL
    @State private var themeSelection: AppTheme = .system
    @State private var languageCode: String = "hr"
    @State private var soundEnabled: Bool = true
    @State private var notificationsEnabled: Bool = true

    // NETWORK
    @State private var serverText: String = ""
    @State private var isTestingConnection: Bool = false
    @State private var connectionStatus: ConnectionStatus? = nil

    // SECURITY
    private let autoLockOptions: [Int] = [0, 1, 5, 15, 30]
    @State private var autoLockSelection: Int = 5
    @State private var panicRequiresPin: Bool = true

    // ABOUT
    private let appVersion: String = "0.1.0"
    private let buildNumber: String = "1"

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider().background(Color.white.opacity(0.15))
            contentArea
        }
        .background(Color.black.opacity(0.40))
        .onAppear {
            serverText = session.serverAddress
            autoLockSelection = session.autoLockMinutes
            themeSelection = AppTheme(rawValue: session.selectedTheme) ?? .system
        }
        .onChange(of: serverText) { newValue in
            session.serverAddress = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .onChange(of: autoLockSelection) { newValue in
            session.autoLockMinutes = newValue
        }
        .onChange(of: themeSelection) { newTheme in
            session.selectedTheme = newTheme.rawValue
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Postavke")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    windowManager.toggleSettings()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
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
                        Text(section.title)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                selectedSection == section
                                ? Color.white.opacity(0.18)
                                : Color.white.opacity(0.05)
                            )
                    )
                    .foregroundColor(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 180)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.04, green: 0.04, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Content area

    private var contentArea: some View {
        Group {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Fake test konekcije (za sada)

    private func runTestConnection() {
        guard !session.serverAddress.isEmpty else { return }

        isTestingConnection = true
        connectionStatus = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isTestingConnection = false

            if session.serverAddress.lowercased().hasPrefix("http") {
                connectionStatus = .ok
            } else {
                connectionStatus = .failed
            }
        }
    }
}
