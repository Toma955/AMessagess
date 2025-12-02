import SwiftUI
#if os(macOS)
import AppKit
#endif

struct MessengerWindow: View {
    @EnvironmentObject var windowManager: WindowManager
    @EnvironmentObject var session: SessionManager

    @StateObject private var roomSession = RoomSessionManager()

    @State private var messageText: String = ""

    @State private var isConnectedToRoom: Bool = false
    @State private var isConnectingToRoom: Bool = false
    @State private var connectStatusText: String? = nil
    @State private var roomId: String = ""
    @State private var isServerConnected: Bool = false

    // SEARCH
    @State private var isSearching: Bool = false
    @State private var searchText: String = ""

    // QUICK SETTINGS
    @State private var showQuickSettings: Bool = false
    @State private var messageTextScale: CGFloat = 1.0
    @State private var sendOnEnter: Bool = false

    // 6 modova pozadine samo za ovaj prozor
    @State private var selectedThemeIndex: Int = 0
    @State private var soundEnabled: Bool = true
    @State private var notificationsEnabled: Bool = true

    // TIMER – 15 min od zadnje poruke
    @State private var remainingSeconds: Int = 15 * 60
    @State private var countdownTimer: Timer? = nil

    private let conversationTitle = "Razgovor"

    private let barWidth: CGFloat = 420
    private let barHeight: CGFloat = 45
    private let controlSize: CGFloat = 30

    // 0 – “prozirno” / glass
    // 1 – tamna
    // 2 – gotovo crna
    // 3 – tamno prozirno plava
    // 4 – tamno prozirno zelena
    // 5 – tamno prozirno ljubičasta
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
                //   HEADER + RAZGOVOR
                // =========================
                HStack {
                    Spacer()

                    MessengerHeaderBar(
                        title: conversationTitle,
                        isActive: isConnectedToRoom,
                        selectedThemeIndex: $selectedThemeIndex,
                        onClose: closeWindow,
                        onMinimize: { },
                        onSearch: {
                            if showQuickSettings { showQuickSettings = false }
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                isSearching.toggle()
                            }
                        },
                        onQuickSettings: {
                            if isSearching { isSearching = false }
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                showQuickSettings.toggle()
                            }
                        },
                        showsBottomBar: showQuickSettings || isSearching
                    ) {
                        VStack(alignment: .leading, spacing: 6) {
                            if showQuickSettings {
                                MessagesQuickSettingsBar(
                                    messageTextScale: $messageTextScale,
                                    sendOnEnter: $sendOnEnter,
                                    soundEnabled: $soundEnabled,
                                    notificationsEnabled: $notificationsEnabled,
                                    remainingSeconds: remainingSeconds,
                                    onSaveConversation: saveConversation
                                )
                            } else if isSearching {
                                MessagesSearchBar(searchText: $searchText)
                            }
                        }
                    }

                    Spacer()
                }

                // LISTA PORUKA
                messagesList

                // DONJI ELEMENT – input bar
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

            } else {
                // =========================
                //   EKRAN ZA PIN / SOBU
                //   (BEZ HEADER BARA)
                // =========================
                Spacer()

                VStack(spacing: 16) {
                    ConnectionToRoomView(
                        title: "Spoji se na sobu",
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
                                    resetCountdown()   // start 15:00
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
            ? chatBackgroundColor   // pozadina samo kad razgovor postoji
            : Color.clear           // na PIN ekranu – nema “chat” pozadine
        )
    }

    // MARK: - SEARCH – highlight poruka

    private var highlightedMessageIDs: Set<UUID> {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        if let date = parseSearchDate(query) {
            let cal = Calendar.current
            let matched = roomSession.messages.filter {
                cal.isDate($0.timestamp, inSameDayAs: date)
            }
            return Set(matched.map { $0.id })
        }

        let lower = query.lowercased()
        let matched = roomSession.messages.filter {
            $0.text.lowercased().contains(lower)
        }
        return Set(matched.map { $0.id })
    }

    private func parseSearchDate(_ text: String) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let formats = ["d.M.yyyy", "dd.MM.yyyy"]

        for f in formats {
            let df = DateFormatter()
            df.locale = Locale(identifier: "hr_HR")
            df.dateFormat = f
            if let d = df.date(from: trimmed) {
                return d
            }
        }
        return nil
    }

    // MARK: - Messages list (grupirano po danu)

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(groupedMessages, id: \.date) { section in
                        Text(dayLabel(for: section.date))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 4)

                        ForEach(section.messages) { msg in
                            MessageBubbleView(
                                message: msg,
                                isHighlighted: highlightedMessageIDs.contains(msg.id),
                                textScale: messageTextScale
                            )
                            .id(msg.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .onChange(of: roomSession.messages.count) { _ in
                if let last = roomSession.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
                resetCountdown()
            }
        }
    }

    private var groupedMessages: [(date: Date, messages: [Message])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: roomSession.messages) { msg in
            cal.startOfDay(for: msg.timestamp)
        }

        return groups.keys.sorted().map { day in
            let msgs = groups[day]!.sorted { $0.timestamp < $1.timestamp }
            return (date: day, messages: msgs)
        }
    }

    private func dayLabel(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            return "Danas"
        } else if cal.isDateInYesterday(date) {
            return "Jučer"
        } else {
            let df = DateFormatter()
            df.dateFormat = "dd.MM.yyyy."
            return df.string(from: date)
        }
    }

    // MARK: - Countdown helperi

    private func startCountdownIfNeeded() {
        guard countdownTimer == nil else { return }

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !isConnectedToRoom {
                countdownTimer?.invalidate()
                countdownTimer = nil
                return
            }

            if remainingSeconds > 0 {
                remainingSeconds -= 1
            }
        }
    }

    private func resetCountdown() {
        remainingSeconds = 15 * 60
        startCountdownIfNeeded()
    }

    // MARK: - Close

    private func closeWindow() {
        roomSession.close()
        countdownTimer?.invalidate()
        countdownTimer = nil

        if let idx = windowManager.windows.firstIndex(
            where: { $0.kind == .messages && !$0.isDocked }
        ) {
            windowManager.windows.remove(at: idx)
        }
    }

    // MARK: - Spremanje razgovora

    private func saveConversation() {
        guard !roomId.isEmpty else {
            print("💾 [SAVE] roomId je prazan – nema aktivnog razgovora.")
            return
        }

        let entries = LogStorage.shared.loadLog(for: roomId)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(entries) else {
            print("💾 [SAVE] Ne mogu kodirati log za razgovor \(roomId)")
            return
        }

        let iso = ISO8601DateFormatter()
        let stamp = iso.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let fileName = "AMessages_\(roomId)_\(stamp).json"

        #if os(macOS)
        if !session.historyDefaultFolderPath.isEmpty {
            let folderURL = URL(fileURLWithPath: session.historyDefaultFolderPath)
            let fileURL = folderURL.appendingPathComponent(fileName)
            do {
                try data.write(to: fileURL)
                print("💾 [SAVE] Spremio razgovor u: \(fileURL.path)")
            } catch {
                print("💾 [SAVE] Greška pri pisanju u zadanu mapu:", error)
            }
        } else {
            let panel = NSSavePanel()
            panel.title = "Spremi razgovor"
            panel.nameFieldStringValue = fileName
            panel.canCreateDirectories = true
            panel.allowedFileTypes = ["json"]

            panel.begin { response in
                if response == .OK, let url = panel.url {
                    do {
                        try data.write(to: url)
                        print("💾 [SAVE] Spremio razgovor u: \(url.path)")
                    } catch {
                        print("💾 [SAVE] Greška pri pisanju:", error)
                    }
                } else {
                    print("💾 [SAVE] Korisnik je odustao od spremanja.")
                }
            }
        }
        #else
        print("💾 [SAVE] Spremanje je za sada implementirano samo za macOS.")
        #endif
    }
}

// MARK: - Bubble view

struct MessageBubbleView: View {
    let message: Message
    let isHighlighted: Bool
    let textScale: CGFloat

    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        return df
    }()

    var body: some View {
        let timeText = Self.timeFormatter.string(from: message.timestamp)

        switch message.direction {
        case .system:
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    Text(message.text)
                        .font(.system(size: 11 * textScale, weight: .medium))
                    Text(timeText)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(6)
                .background(
                    Capsule()
                        .fill(isHighlighted
                              ? Color.white.opacity(0.30)
                              : Color.white.opacity(0.12))
                )
                Spacer()
            }

        case .incoming:
            HStack(alignment: .bottom, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.text)
                        .font(.system(size: 13 * textScale))
                    Text(timeText)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isHighlighted
                              ? Color.white.opacity(0.25)
                              : Color.white.opacity(0.12))
                )
                Spacer(minLength: 20)
            }

        case .outgoing:
            HStack(alignment: .bottom, spacing: 6) {
                Spacer(minLength: 20)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(message.text)
                        .font(.system(size: 13 * textScale))
                    Text(timeText)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isHighlighted
                              ? Color.green.opacity(0.9)
                              : Color.green.opacity(0.7))
                )
            }
        }
    }
}
