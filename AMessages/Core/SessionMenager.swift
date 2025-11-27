import Foundation
import CryptoKit

final class SessionManager: ObservableObject {
    @Published var isUnlocked: Bool = false
    var masterKey: SymmetricKey?

    @Published var showMainWindow: Bool = true

    // Island / self-ID
    @Published var islandCurrentId: String = ""

    // Call setup stanje
    @Published var pendingCallId: String? = nil
    @Published var pendingCallerName: String = ""
    @Published var requireCallerName: Bool = true

    // Island collapse signal
    @Published var islandCollapseTick: Int = 0

    // MARK: - UI & tema

    /// Adresa servera (npr. https://api.amessages.app)
    @Published var serverAddress: String = ""

    /// Auto-lock u minutama (0 = isključeno)
    @Published var autoLockMinutes: Int = 5

    /// Tema – string, da bude jednostavno (system / dark / light / lava ...)
    @Published var selectedTheme: String = "system"

    /// Pomoćni: interval u sekundama (za timer u budućnosti)
    var autoLockInterval: TimeInterval {
        autoLockMinutes <= 0 ? 0 : TimeInterval(autoLockMinutes * 60)
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
