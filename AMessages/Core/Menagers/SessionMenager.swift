import Foundation
import CryptoKit

final class SessionManager: ObservableObject {
    @Published var isUnlocked: Bool = false
    var masterKey: SymmetricKey?

    @Published var showMainWindow: Bool = true

    // Island / self-ID
    @Published var islandCurrentId: String = ""
    
    // status bar / prečaci – vidljivost
    @Published var showSessionIdField: Bool = true

    @Published var showMessagesEntry: Bool = true
    @Published var showIndependentMessagesEntry: Bool = true
    @Published var showContactsEntry: Bool = true
    @Published var showHistoryEntry: Bool = true
    @Published var showNotesEntry: Bool = true


    @Published var showLockButton: Bool = true
    @Published var showQuitButton: Bool = true
    @Published var focusModeEnabled: Bool = false


    // Call setup stanje
    @Published var pendingCallId: String? = nil
    @Published var pendingCallerName: String = ""
    @Published var requireCallerName: Bool = true

    // Island collapse signal
    @Published var islandCollapseTick: Int = 0

    // MARK: - UI & tema

    /// HTTP baza (za sada: tvoj Render server)
    @Published var serverAddress: String = "https://amessagesserver.onrender.com"

    /// Auto-lock u minutama (0 = isključeno)
    @Published var autoLockMinutes: Int = 5

    /// Tema – string, da bude jednostavno (system / dark / light / lava ...)
    @Published var selectedTheme: String = "system"

    /// Pomoćni: interval u sekundama (za timer u budućnosti)
    var autoLockInterval: TimeInterval {
        autoLockMinutes <= 0 ? 0 : TimeInterval(autoLockMinutes * 60)
    }

    /// Iz HTTP → WebSocket URL (npr. https://host → wss://host)
    var webSocketURLString: String {
        let trimmed = serverAddress.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("https://") {
            let hostPart = trimmed.dropFirst("https://".count)
            return "wss://" + hostPart
        } else if trimmed.hasPrefix("http://") {
            let hostPart = trimmed.dropFirst("http://".count)
            return "ws://" + hostPart
        } else {
            // ako user ručno unese već wss://, samo vrati to
            return trimmed
        }
    }

    // widgets
    @Published var islandEnabled: Bool = true
    @Published var dockEnabled: Bool = true
    @Published var backgroundAnimationIntensity: Double = 1.0

    // datoteke
    @Published var rememberDefaultFolders: Bool = false
    @Published var notesDefaultFolderPath: String = ""
    @Published var historyDefaultFolderPath: String = ""

    func lock() {
        isUnlocked = false
        masterKey = nil
        showMainWindow = true
        pendingCallId = nil
        pendingCallerName = ""
    }

    /// Pozovi kad je preloader završio s ispravnim file+PIN
    func completeUnlock() {
        isUnlocked = true
    }
}
