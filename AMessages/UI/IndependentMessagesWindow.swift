import SwiftUI

struct IndependentMessagesWindow: View {
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var session: SessionManager

    @StateObject private var roomSession = RoomSessionManager()

    // stanje konekcije
    @State private var roomId: String = ""
    @State private var isConnectedToRoom: Bool = false
    @State private var isConnectingToRoom: Bool = false
    @State private var isServerConnected: Bool = false
    @State private var connectStatusText: String? = nil

    // tema (isti index kao u Messengeru / Settingsu)
    @State private var selectedThemeIndex: Int = 0

    // ista logika pozadine kao u MessengerWindow
    private var chatBackgroundColor: Color {
        switch selectedThemeIndex {
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
            return Color.black.opacity(0.12)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isConnectedToRoom {
                // ======================================
                //    HEADER + "AGENT" UMJESTO CHATA
                // ======================================
                HStack {
                    Spacer()

                    MessengerHeaderBar(
                        title: "Neovisne poruke",
                        isActive: isConnectedToRoom,
                        selectedThemeIndex: $selectedThemeIndex,
                        onClose: closeWindow,
                        onMinimize: { },
                        onSearch: { },          // zasad ne koristimo
                        onQuickSettings: { },   // zasad ne koristimo
                        showsBottomBar: false
                    ) {
                        EmptyView()             // nema donjeg bara (quick settings/search)
                    }

                    Spacer()
                }

                ZStack {
                    chatBackgroundColor
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        Text("Agent za neovisne poruke")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        if !roomId.isEmpty {
                            Text("Spojeno na sobu: \(roomId)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Text("Ovdje će kasnije doći vizualni agent koji pomaže oko konekcije, statusa i potencijalnih problema. Za sada je ovo samo prikaz nakon uspješnog spajanja.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(16)
                }

            } else {
                // ==============================
                //    EKRAN ZA PIN / SOBU
                // ==============================
                Spacer()

                VStack(spacing: 16) {
                    ConnectionToRoomView(
                        title: "Neovisne poruke",
                        buttonTitle: "Poveži se",
                        showsConnectButton: true,
                        isServerConnected: isServerConnected,
                        message: connectStatusText
                    ) { code in
                        roomId = code
                        isConnectingToRoom = true
                        connectStatusText = "Povezujem se na server…"

                        roomSession.joinRoom(code: code, using: session) { success, errorText in
                            DispatchQueue.main.async {
                                isConnectingToRoom = false
                                if success {
                                    isServerConnected = true
                                    isConnectedToRoom = true
                                    connectStatusText = nil
                                } else {
                                    isServerConnected = false
                                    connectStatusText = errorText ?? "Neuspjelo povezivanje."
                                }
                            }
                        }
                    } onCancel: {
                        closeWindow()
                    }

                    if isConnectingToRoom {
                        HStack(spacing: 10) {
                            ProgressView()
                                .scaleEffect(0.9)
                            Text("Čekam drugu stranu…")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.white.opacity(0.85))
                    }
                }
                .frame(maxWidth: 420)

                Spacer()
            }
        }
        .background(
            isConnectedToRoom
            ? chatBackgroundColor
            : Color.clear
        )
        .onAppear {
            // sinkroniziraj temu s globalnim stanjem
            if let raw = Int(session.selectedTheme) {
                selectedThemeIndex = raw
            } else {
                selectedThemeIndex = 0
            }
        }
        .onChange(of: selectedThemeIndex) { newValue in
            session.selectedTheme = String(newValue)
        }
    }

    // MARK: - Close

    private func closeWindow() {
        roomSession.close()

        if let idx = windowManager.windows.firstIndex(
            where: { $0.kind == .independentMessages && !$0.isDocked }
        ) {
            windowManager.windows.remove(at: idx)
        }
    }
}
