import SwiftUI

struct IndependentMessagesWindow: View {
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var conversationManager: ConversationManager

    @StateObject private var roomSession = RoomSessionManager()
    
    // Agent context i watchman za sistemske poruke
    @State private var agentContext: IndependentMessagesAgentContext?
    @State private var watchman: IndependentMessagesWatchman?

    // stanje konekcije
    @State private var roomId: String = ""
    @State private var isConnectedToRoom: Bool = false
    @State private var isConnectingToRoom: Bool = false
    @State private var isServerConnected: Bool = false
    @State private var connectStatusText: String? = nil

    // tema (isti index kao u Messengeru / Settingsu)
    @State private var selectedThemeIndex: Int = 0

    // input bar
    @State private var messageText: String = ""
    @State private var sendOnEnter: Bool = false
    private let barWidth: CGFloat = 420
    private let barHeight: CGFloat = 45
    private let controlSize: CGFloat = 30

    // indikator veze
    @State private var isConnectionIndicatorExpanded: Bool = false

    // kako trenutno prikazujemo tip veze
    private var connectionMode: ConnectionIndicator.Mode {
        if !isConnectedToRoom { return .notConnected }
        // zasad: ako pri joinu server radi → ovo je “Ser”
        return isServerConnected ? .server : .notConnected
    }

    // pozadina chata (kopirano iz MessengerWindow)
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
                // =========================
                //   HEADER + “AGENT” + INPUT
                // =========================
                HStack {
                    Spacer()

                    // HEADER + indikator u istom crnom baru
                    ZStack(alignment: .trailing) {
                        MessengerHeaderBar(
                            title: "Neovisne poruke",
                            isActive: isConnectedToRoom,
                            selectedThemeIndex: $selectedThemeIndex,
                            onClose: closeWindow,
                            onMinimize: { },
                            onSearch: { },
                            onQuickSettings: { },
                            showsBottomBar: false
                        ) {
                            EmptyView()
                        }
                        
                    }

                    Spacer()
                }

                ZStack {
                    chatBackgroundColor
                        .ignoresSafeArea()

                    VStack(spacing: 12) {

                        // “agent” blok
                        VStack(spacing: 8) {
                            Text("Agent za neovisne poruke")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            if !roomId.isEmpty {
                                Text("Spojeno na sobu: \(roomId)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            Text("Ovdje će kasnije doći vizualni prikaz P2P/ARP/Loc/Blo topologije i dijagnostike.")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 4)

                        Spacer()

                        // donji input bar za slanje poruka
                        HStack {
                            Spacer()
                            MessagesInputBar(
                                messageText: $messageText,
                                sendOnEnter: sendOnEnter,
                                controlSize: controlSize,
                                barWidth: barWidth,
                                barHeight: barHeight
                            ) { text in
                                roomSession.sendText(text)
                            }
                            Spacer()
                        }
                        .padding(.bottom, 8)
                    }
                    .padding(.top, 8)
                }

            } else {
                // =========================
                //   EKRAN ZA PIN / CONNECT
                // =========================
                ZStack {
                    Color.clear

                    VStack {
                        Spacer()

                        ConnectionToRoomView(
                            title: "Neovisne poruke",
                            buttonTitle: "Poveži se",
                            showsConnectButton: true,
                            isServerConnected: isServerConnected,
                            message: connectStatusText
                        ) { code in
                            // onConnect
                            roomId = code
                            isConnectingToRoom = true
                            connectStatusText = "Povezujem se na server…"
                            
                            // Inicijaliziraj agent context i watchman PRIJE spajanja
                            // Ovo je kritično - agent mora biti spreman prije nego što se primi session_ready
                            setupAgentSystem()
                            
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
                        .frame(maxWidth: 420)

                        if isConnectingToRoom {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .scaleEffect(0.9)
                                Text("Čekam drugu stranu…")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.top, 8)
                        }

                        Spacer()
                    }
                }
                .background(
                    Color.clear   // na PIN ekranu – bez chat pozadine
                )
            }
        }
        .background(
            isConnectedToRoom
            ? chatBackgroundColor
            : Color.clear
        )
    }

    // MARK: - Agent Setup
    
    private func setupAgentSystem() {
        // Kreiraj agent context ako već nije kreiran
        if agentContext == nil {
            let context = IndependentMessagesAgentContext(
                roomSessionManager: roomSession,
                relayClient: RelayClient.shared,
                conversationManager: conversationManager
            )
            agentContext = context
            
            // Kreiraj i pokreni watchman
            let watch = IndependentMessagesWatchman(context: context)
            watch.start()
            watchman = watch
            
            print("[IndependentMessagesWindow] ✅ Agent sistem inicijaliziran i pokrenut")
        }
    }
    
    // MARK: - Close

    private func closeWindow() {
        roomSession.close()
        
        // Zaustavi watchman
        watchman?.stop()
        watchman = nil
        agentContext = nil

        if let idx = windowManager.windows.firstIndex(
            where: { $0.kind == .independentMessages && !$0.isDocked }
        ) {
            windowManager.windows.remove(at: idx)
        }
    }
}
