// IdentityStore
// Drži informacije o identitetu peer-ova (javne ključeve, povijest endpointa).

import Foundation

final class IdentityStore {

    static let shared = IdentityStore()

    private init() {}

    private var endpointsByPeer: [String: [String]] = [:]

    func recordEndpoint(_ endpoint: String, forPeer peerId: String) {
        var list = endpointsByPeer[peerId] ?? []
        list.append(endpoint)
        endpointsByPeer[peerId] = list
        print("[IdentityStore] recordEndpoint peer=\(peerId), endpoint=\(endpoint)")
    }

    func knownEndpoints(forPeer peerId: String) -> [String] {
        endpointsByPeer[peerId] ?? []
    }

    func debugPrintStore() {
        print("[IdentityStore] store = \(endpointsByPeer)")
    }
}
