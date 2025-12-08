// ConnectionAgentView
// Glavni UI prikaz za agenta: status badge + (opcionalno) mrežna topologija.

import SwiftUI

import Foundation

/// ViewModel za neovisne poruke – drži store agenata i osnovnu logiku.
final class IndependentMessagesAgentViewModel: ObservableObject {

    @Published var store: ConnectionAgentStore

    init(store: ConnectionAgentStore = ConnectionAgentStore()) {
        self.store = store

        // Ako nema nijednog agenta, dodaj jedan demo da UI nije prazan
        if self.store.agents.isEmpty {
            let demo = ConnectionAgent(
                name: "Demo agent",
                details: "P2P demo profil",
                iconSystemName: "personalhotspot",
                colorTag: "green",
                roomCode: ""
            )
            self.store.add(demo)
        }
    }

    func select(_ agent: ConnectionAgent) {
        store.select(agent)
        store.markSelectedAsUsed()
    }

    func createNewAgent() {
        let newAgent = ConnectionAgent.empty()
        store.add(newAgent)
    }
}

