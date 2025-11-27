import Foundation
import CryptoKit

final class Preloader: ObservableObject {
    @Published var pin: String = ""
    @Published var profileURL: URL?
    @Published var errorMessage: String?

    var canUnlock: Bool {
        profileURL != nil && pin.count == 12
    }

    func setProfile(url: URL) {
        profileURL = url
        errorMessage = nil
    }

    func unlock(using session: SessionManager) {
        guard canUnlock else {
            errorMessage = "Potrebna je datoteka i PIN od 12 znakova."
            return
        }

        do {
            let key = try KeyDerivationService.deriveMasterKey(
                profileURL: profileURL,
                pin: pin
            )

            session.masterKey = key
            session.completeUnlock()

            errorMessage = nil
        } catch {
            errorMessage = "Neuspjela derivacija ključa."
        }
    }
}
