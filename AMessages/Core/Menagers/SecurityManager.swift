// SecurityManager
// Centralno mjesto za sigurnosne provjere: identitet peer-a, promjena endpointa,
// moguće MITM obrasce, rate limiting / abuse.

import Foundation

final class SecurityManager {

    static let shared = SecurityManager()

    private init() {}

    func validateEndpointChange(forPeer peerId: String,
                                oldEndpoint: String?,
                                newEndpoint: String) -> Bool {
        // TODO: kasnije primijeniti stvarnu logiku i zapis u IdentityStore.
        print("[SecurityManager] validateEndpointChange peer=\(peerId), old=\(oldEndpoint ?? "nil"), new=\(newEndpoint)")
        return true
    }

    /// Pomoćna funkcija za debug.
    func debugPrintStatus() {
        print("[SecurityManager] debugPrintStatus() placeholder")
    }
}
